# ABOUTME: Behavioral tests for the guardrails kit's bin/ scripts, run against a stubbed kubectl.
# ABOUTME: Covers the checks that once piped kubectl into grep -q under pipefail and misread on SIGPIPE (#34).

from __future__ import annotations

import os
import shutil
import subprocess
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parent.parent
KIT_BIN = REPO_ROOT / "guardrails-three-layer" / "bin"
EVALUATE = KIT_BIN / "evaluate.sh"
INSTALL_LAYER_2 = KIT_BIN / "install-layer-2.sh"
BASH = shutil.which("bash")
assert BASH is not None, "bash is required on PATH to run the kit tests"

# Enough lines after the match that the producer is still writing, well past
# the pipe buffer, when grep -q has its answer and exits.
FILLER_LINES = 200_000


def filler(prefix: str) -> str:
    return "".join(f"{prefix}-{i:06d}\n" for i in range(FILLER_LINES))


def stub_kubectl(tmp_path: Path, cases: str, outputs: dict[str, str]) -> Path:
    """A kubectl on PATH whose replies are the `case "$*"` arms given, with large outputs in files.

    Each key of `outputs` is written to <bindir>/<key>.txt, and an arm can
    `cat "$OUT/<key>.txt"` to print it. Calls no arm handles exit 1. gh and
    pre-commit are stubbed too, so the real ones never reach a network or the
    host's install.
    """
    bindir = tmp_path / "bin"
    bindir.mkdir()
    for name, text in outputs.items():
        (bindir / f"{name}.txt").write_text(text)
    kubectl = bindir / "kubectl"
    kubectl.write_text(
        "#!/usr/bin/env bash\n"
        f'OUT="{bindir}"\n'
        f'echo "$*" >> "$OUT/calls.log"\n'
        'case "$*" in\n'
        f"{cases}\n"
        "    *) exit 1 ;;\n"
        "esac\n"
    )
    kubectl.chmod(0o755)
    for name in ("gh", "pre-commit"):
        stub = bindir / name
        stub.write_text("#!/usr/bin/env bash\nexit 1\n")
        stub.chmod(0o755)
    return bindir


def run(
    script: Path,
    bindir: Path,
    *,
    cwd: Path,
    home: Path,
    stdin: str = "",
    env: dict[str, str] | None = None,
) -> subprocess.CompletedProcess[str]:
    env = {
        **os.environ,
        **(env or {}),
        "PATH": f"{bindir}{os.pathsep}{os.environ['PATH']}",
        "HOME": str(home),
    }
    return subprocess.run(
        [BASH, str(script)],
        input=stdin,
        capture_output=True,
        text=True,
        cwd=cwd,
        env=env,
        timeout=60,
    )


# ─── install-layer-2.sh ────────────────────────────────────────────────

VAP_LINE = (
    "validatingadmissionpolicies   admissionregistration.k8s.io/v1   false   "
    "ValidatingAdmissionPolicy\n"
)
API_HEADER = "NAME   SHORTNAMES   APIVERSION   NAMESPACED   KIND\n"

INSTALL_CASES = """
    "cluster-info") exit 0 ;;
    "config current-context") echo test-ctx ;;
    "config view --minify -o jsonpath="*) echo https://127.0.0.1:6443 ;;
    "get crd clusterpolicies.kyverno.io") exit 1 ;;
    "api-resources") cat "$OUT/api-resources.txt" || exit; exit "${API_EXIT:-0}" ;;
    "apply -f "*) echo "applied $3" ;;
"""


def install_layer_2(tmp_path: Path, listing: str, api_exit: int = 0):
    bindir = stub_kubectl(tmp_path, INSTALL_CASES, {"api-resources": listing})
    return run(
        INSTALL_LAYER_2,
        bindir,
        cwd=tmp_path,
        home=tmp_path,
        stdin="y\n",
        env={"API_EXIT": str(api_exit)},
    )


def test_install_layer_2_applies_vap_when_the_listing_is_long(tmp_path: Path) -> None:
    # The match comes first and the listing runs on far past it, so grep -q
    # exits while kubectl is still writing. The API is there; it must be used.
    result = install_layer_2(tmp_path, API_HEADER + VAP_LINE + filler("widgets   example.io/v1"))
    assert result.returncode == 0, result.stderr
    assert "deny-privileged.yaml" in result.stdout
    assert "not available on this API server" not in result.stdout


def test_install_layer_2_applies_vap_despite_partial_discovery(tmp_path: Path) -> None:
    # kubectl api-resources exits 1 when one API group fails discovery (a
    # down metrics-server is the usual one) but still lists every other group.
    result = install_layer_2(tmp_path, API_HEADER + VAP_LINE, api_exit=1)
    assert result.returncode == 0, result.stderr
    assert "deny-privileged.yaml" in result.stdout


def test_install_layer_2_skips_vap_when_the_api_is_absent(tmp_path: Path) -> None:
    result = install_layer_2(tmp_path, API_HEADER + filler("widgets   example.io/v1"))
    assert result.returncode == 0, result.stderr
    assert "deny-privileged.yaml" not in result.stdout
    assert "not available on this API server. Skipping." in result.stdout


# ─── evaluate.sh ───────────────────────────────────────────────────────

EVALUATE_CASES = """
    "config current-context") echo test-ctx ;;
    "cluster-info") exit 0 ;;
    "get ds -A") cat "$OUT/daemonsets.txt" ;;
    "get ns ai-workspace -o jsonpath="*) printf restricted ;;
    "get ns") cat "$OUT/namespaces.txt" ;;
    "auth can-i --list") cat "$OUT/can-i.txt" ;;
    "get clusterroles cluster-admin -o yaml") cat "$OUT/cluster-admin.txt" ;;
"""


@pytest.fixture(scope="module")
def evaluation(tmp_path_factory: pytest.TempPathFactory) -> str:
    """evaluate.sh's report on a cluster whose listings each match first, then run long.

    kyverno and falco namespaces are absent, so the Falco check falls through
    to the daemonset listing. The repo has only a .yml workflow, no .yaml.
    """
    tmp_path = tmp_path_factory.mktemp("evaluate")
    repo = tmp_path / "repo"
    (repo / ".github" / "workflows").mkdir(parents=True)
    (repo / ".github" / "workflows" / "security-scan.yml").write_text("on: push\n")
    subprocess.run(["git", "init", "-q", str(repo)], check=True)
    bindir = stub_kubectl(
        tmp_path,
        EVALUATE_CASES,
        {
            "daemonsets": "NAMESPACE   NAME   DESIRED\nsecurity   falco   3\n"
            + filler("apps   node-agent"),
            "namespaces": "NAME   STATUS   AGE\nai-workspace   Active   1d\n"
            + filler("tenant   Active   1d"),
            "can-i": "Resources   Non-Resource URLs   Resource Names   Verbs\n"
            + filler("widgets.example.io   []   []   [get]"),
            "cluster-admin": "apiVersion: rbac.authorization.k8s.io/v1\nkind: ClusterRole\n"
            "metadata:\n  name: cluster-admin\nrules:\n" + filler("- verbs: ['get']  #"),
        },
    )
    home = tmp_path / "home"
    home.mkdir()
    result = run(EVALUATE, bindir, cwd=repo, home=home)
    assert result.returncode == 0, result.stderr
    return result.stdout


def verdict(report: str, label: str) -> str:
    lines = [line for line in report.splitlines() if line.strip().startswith(label)]
    assert len(lines) == 1, f"expected one {label!r} line in:\n{report}"
    return lines[0].rsplit("[", 1)[1].split("]", 1)[0].strip()


@pytest.mark.parametrize(
    "label",
    [
        "Falco installed",
        "ai-workspace ns with PSS restricted",
        "GitHub Actions workflow for security/policy",
    ],
)
def test_evaluate_passes_checks_with_long_listings(evaluation: str, label: str) -> None:
    assert verdict(evaluation, label) == "PASS"


def test_evaluate_reaches_the_cluster_admin_audit(evaluation: str) -> None:
    # Reached only when both the can-i listing and the cluster-admin role
    # read as present.
    assert verdict(evaluation, "cluster-admin bindings audited") == "?"
