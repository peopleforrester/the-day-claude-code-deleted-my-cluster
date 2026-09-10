#!/usr/bin/env bash
# ABOUTME: Blocks writes to sensitive files (.env, credentials, keys, secrets).
# ABOUTME: Returns exit 2 (BLOCK) if the target file matches a sensitive pattern.

set -euo pipefail

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ -z "$FILE" ]]; then
    exit 0
fi

BASENAME=$(basename "$FILE")
LOWER_BASENAME=$(echo "$BASENAME" | tr '[:upper:]' '[:lower:]')

# Block exact sensitive filenames
case "$LOWER_BASENAME" in
    .env|.env.*|*.pem|*.key|*.p12|*.pfx|*.jks)
        echo "BLOCKED: Cannot write to sensitive file: $BASENAME" >&2
        exit 2
        ;;
esac

# Source and doc files legitimately reference these words in their NAME
# (tokens.py, credentials_manager.ts, password-reset.md). The keyword block
# below targets secret-bearing DATA files, not source, so exempt clear
# code/doc extensions from it. The exact-secret-file block above (.env, *.key,
# *.pem, ...) still fires for those regardless of this exemption.
SOURCE_EXT=0
case "$LOWER_BASENAME" in
    *.py|*.js|*.ts|*.tsx|*.jsx|*.mjs|*.cjs|*.go|*.rs|*.rb|*.java|*.kt|*.c|*.cc \
    |*.cpp|*.h|*.hpp|*.cs|*.php|*.lua|*.sh|*.bash|*.zsh|*.md|*.rst)
        SOURCE_EXT=1
        ;;
esac

# Block files with sensitive keywords in the name (data files only)
if [[ "$SOURCE_EXT" -eq 0 ]]; then
    case "$LOWER_BASENAME" in
        *credential*|*secret*|*password*|*token*|*apikey*|*api_key*|*private_key*)
            echo "BLOCKED: Cannot write to file with sensitive name: $BASENAME" >&2
            exit 2
            ;;
    esac
fi

# Block known sensitive config files
case "$BASENAME" in
    id_rsa|id_ed25519|id_ecdsa|authorized_keys|known_hosts)
        echo "BLOCKED: Cannot write to SSH file: $BASENAME" >&2
        exit 2
        ;;
esac

exit 0
