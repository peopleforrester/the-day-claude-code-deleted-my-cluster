#!/usr/bin/env bash
# ABOUTME: Copy Layer 1 client-side hooks and pre-commit config into the current repo, then activate them.
# ABOUTME: Does NOT apply server-side branch protection - that requires your GitHub admin consent (see START_HERE.md).
set -euo pipefail

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Run this from inside the repo you want to harden." >&2
    exit 1
fi

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DST="$(git rev-parse --show-toplevel)"

if [[ "${SRC}" == "${DST}" ]]; then
    echo "You're in the source repo - nothing to copy. Open the target repo instead." >&2
    exit 2
fi

echo "Copying Layer 1 client-side hooks into ${DST}"
mkdir -p "${DST}/.githooks" "${DST}/scripts"
cp -a "${SRC}/layer-1-git-ci/.githooks/." "${DST}/.githooks/"
cp    "${SRC}/layer-1-git-ci/.pre-commit-config.yaml" "${DST}/.pre-commit-config.yaml"
cp    "${SRC}/layer-1-git-ci/scripts/install-hooks.sh" "${DST}/scripts/install-hooks.sh"
chmod +x "${DST}/.githooks/"* "${DST}/scripts/install-hooks.sh"

echo "Copying GitHub Actions workflows"
mkdir -p "${DST}/.github/workflows"
cp -a "${SRC}/layer-1-git-ci/.github/workflows/." "${DST}/.github/workflows/"
cp    "${SRC}/layer-1-git-ci/.github/CODEOWNERS"  "${DST}/.github/CODEOWNERS"

echo "Activating git hooks"
(cd "${DST}" && ./scripts/install-hooks.sh)

cat <<'EOF'

Layer 1 client-side is installed.

Remaining server-side steps (required - client hooks can be bypassed with --no-verify):

  1) Set branch protection on main. Either:
       gh api -X PUT repos/<owner>/<repo>/branches/main/protection ...
     (see START_HERE.md minute 20-25)
     or use the Terraform in layer-1-git-ci/terraform/branch-protection.tf

  2) Commit and push the .githooks, .pre-commit-config.yaml, and .github/ additions.

  3) Open a PR to observe the required status checks running.

EOF
