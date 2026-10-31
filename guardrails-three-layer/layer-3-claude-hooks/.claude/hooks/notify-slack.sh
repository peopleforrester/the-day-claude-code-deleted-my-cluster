#!/usr/bin/env bash
# ABOUTME: Layer 3 Notification hook - forward permission prompts and idle events to Slack.
# ABOUTME: Requires SLACK_WEBHOOK_URL. Runs async via settings.json so it never blocks the UI.
set -euo pipefail
[[ -z "${SLACK_WEBHOOK_URL:-}" ]] && exit 0

INPUT="$(cat)"
MSG="$(jq -r '.message' <<<"${INPUT}")"
TITLE="$(jq -r '.title // "Claude Code"' <<<"${INPUT}")"
SESSION="$(jq -r '.session_id' <<<"${INPUT}")"

curl -sS --max-time 5 \
    -H 'Content-Type: application/json' \
    -d "$(jq -n --arg t "${TITLE}" --arg m "${MSG}" --arg s "${SESSION}" '{
        blocks: [
          { type: "header", text: { type: "plain_text", text: ("Claude Code: " + $t) } },
          { type: "section", text: { type: "mrkdwn", text: ("*Session:* `" + $s + "`\n" + $m) } }
        ]
      }')" \
    "${SLACK_WEBHOOK_URL}" >/dev/null

exit 0
