#!/usr/bin/env bash
# ABOUTME: One-shot installer for Layer 1 client-side hooks.
# ABOUTME: Sets core.hooksPath, marks hooks executable, installs pre-commit framework if available.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

git config core.hooksPath .githooks
chmod +x .githooks/* 2>/dev/null || true
chmod +x scripts/*.sh 2>/dev/null || true

if command -v pre-commit >/dev/null 2>&1; then
    pre-commit install --hook-type pre-commit --hook-type commit-msg --hook-type pre-push
    echo "pre-commit framework hooks installed."
else
    cat <<'EOF'
pre-commit framework not installed. Install it with:

    pip install --user pre-commit
    # or
    brew install pre-commit

Then re-run this script.
EOF
fi

echo
echo "Layer 1 client-side hooks ready."
echo "Verify with:"
echo "    echo 'kubectl delete ns kube-system' > /tmp/demo.sh"
echo "    git add /tmp/demo.sh && git commit -m 'feat: trip guard'"
echo "    (should be rejected)"
