#!/usr/bin/env bash
# ABOUTME: Copy the .claude/ directory (settings.json + hooks) into the target repo and commit-ready.
# ABOUTME: Run this from inside the repo you want Claude Code guardrails in, not from the guardrails repo itself.
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

if [[ -d "${DST}/.claude" ]]; then
    echo "Target already has a .claude/ dir: ${DST}/.claude"
    echo "Not overwriting. Manually merge if needed."
    exit 3
fi

echo "Copying Layer 3 Claude Code hooks into ${DST}/.claude"
cp -a "${SRC}/layer-3-claude-hooks/.claude" "${DST}/.claude"
chmod +x "${DST}/.claude/hooks/"*.sh

if [[ ! -f "${DST}/CLAUDE.md" ]]; then
    echo "Seeding CLAUDE.md with the destructive-ops policy"
    cp "${SRC}/layer-3-claude-hooks/CLAUDE.md" "${DST}/CLAUDE.md"
else
    echo "Target already has CLAUDE.md - NOT overwriting."
    echo "Consider appending the destructive-ops policy section from:"
    echo "    ${SRC}/layer-3-claude-hooks/CLAUDE.md"
fi

cat <<'EOF'

Layer 3 installed.

Verify:

  1) Start a fresh Claude Code session in this repo.

  2) Ask Claude to run one of:
       rm -rf /var/lib/etcd
       kubectl delete ns kube-system
       kubeadm reset

     Each should be denied at PreToolUse with a clear reason.

  3) Commit so the whole team inherits the hooks:
       git add .claude CLAUDE.md
       git commit -m "security: add Layer 3 Claude Code hooks"
       git push

EOF
