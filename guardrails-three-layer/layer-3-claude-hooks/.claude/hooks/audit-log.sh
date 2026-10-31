#!/usr/bin/env bash
# ABOUTME: Layer 3 PostToolUse hook - append every tool call to a local JSONL audit log.
# ABOUTME: Optionally ships to Splunk HEC, Datadog Logs, or Loki via env vars.
set -euo pipefail

LOG_DIR="${CLAUDE_AUDIT_DIR:-${HOME}/.claude/audit}"
mkdir -p "${LOG_DIR}"
LOG_FILE="${LOG_DIR}/$(date -u +%Y-%m-%d).jsonl"

INPUT="$(cat)"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

RECORD="$(jq --arg ts "${TS}" \
             --arg host "$(hostname)" \
             --arg user "$(whoami)" \
  '{
    ts: $ts,
    host: $host,
    user: $user,
    session_id: .session_id,
    event: .hook_event_name,
    tool: .tool_name,
    input: .tool_input,
    response: .tool_response,
    cwd: .cwd
  }' <<<"${INPUT}")"

echo "${RECORD}" >> "${LOG_FILE}"

# Splunk HEC
if [[ -n "${SPLUNK_HEC_URL:-}" && -n "${SPLUNK_HEC_TOKEN:-}" ]]; then
    curl -sS --max-time 5 -k \
        -H "Authorization: Splunk ${SPLUNK_HEC_TOKEN}" \
        -d "$(jq -n --argjson e "${RECORD}" '{event: $e, sourcetype: "claude-code:hooks"}')" \
        "${SPLUNK_HEC_URL}/services/collector/event" >/dev/null 2>&1 || true
fi

# Datadog
if [[ -n "${DD_API_KEY:-}" ]]; then
    curl -sS --max-time 5 \
        -H "DD-API-KEY: ${DD_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "$(jq -n --argjson e "${RECORD}" '[{ddsource: "claude-code", service: "claude-hooks", message: ($e | tostring)}]')" \
        "https://http-intake.logs.datadoghq.com/api/v2/logs" >/dev/null 2>&1 || true
fi

# Loki
if [[ -n "${LOKI_URL:-}" ]]; then
    NS="$(date +%s)000000000"
    curl -sS --max-time 5 \
        -H "Content-Type: application/json" \
        -d "$(jq -n --arg ns "${NS}" --argjson r "${RECORD}" \
              '{streams:[{stream:{job:"claude-code"},values:[[$ns,($r|tostring)]]}]}')" \
        "${LOKI_URL}/loki/api/v1/push" >/dev/null 2>&1 || true
fi

exit 0
