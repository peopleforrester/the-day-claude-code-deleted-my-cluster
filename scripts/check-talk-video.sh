#!/usr/bin/env bash
# ABOUTME: Checks whether the DevOpsDays Portland 2026 Ignite recording has been
# ABOUTME: published yet, and reports what it found rather than what it assumes.
#
# Background: the Ignite ran 2026-09-10. The organizers said on 2026-09-15 that
# videos "should be available online once we're done editing in a couple weeks".
# Nothing else about that talk was recorded (see issue #7), so the video is the
# only artifact that might still exist. This script exists so the window does not
# close unnoticed.
#
# Checked 2026-09-18: the channel below carries playlists for 2016, 2017, 2018,
# 2019 and 2021, and nothing since. The last DevOpsDays Portland video published
# there is five years old. Treat "videos will be up in a couple of weeks" as a
# stated intention with a poor base rate behind it, and do not read silence from
# this channel as proof the recording does not exist. It may land somewhere else
# entirely, or not at all.
#
# NOTE ON MATCHING: --flat-playlist returns upload_date as NA, so the year filter
# matches the year in the video TITLE. DevOpsDays titles have carried the year
# consistently since 2016, but that is a convention, not a guarantee.
#
# Install as a weekly cron. Cron's PATH will not find yt-dlp or gog, so set it:
#   17 9 * * 1 export PATH=$HOME/.local/bin:/home/linuxbrew/.linuxbrew/bin:$PATH; \
#     $HOME/repos/events/the-day-claude-code-deleted-my-cluster/scripts/check-talk-video.sh \
#     --notify >> $HOME/logs/talk-video.log 2>&1

set -euo pipefail

readonly CHANNEL="https://www.youtube.com/channel/UCxzmx6LKP5PmcR1wVUj1dxw"
readonly PATTERN='claude|cluster|forrester|ignite'
readonly YEAR='2026'
readonly NOTIFY_TO="michaelrishiforrester@gmail.com"

readonly EXIT_FOUND=0
readonly EXIT_NOT_YET=1
readonly EXIT_INCONCLUSIVE=2

usage() {
    printf 'Usage: %s [--notify]\n\n' "$(basename "${BASH_SOURCE[0]}")"
    printf '  --notify   email %s if the recording has appeared\n\n' "${NOTIFY_TO}"
    printf 'Exit codes: %d found, %d not yet, %d inconclusive\n' \
        "${EXIT_FOUND}" "${EXIT_NOT_YET}" "${EXIT_INCONCLUSIVE}"
}

require_tool() {
    local tool="$1"
    command -v "${tool}" >/dev/null 2>&1 || {
        printf 'FAIL: %s is not on PATH. Under cron, export the full PATH.\n' "${tool}" >&2
        printf 'See rules/tools/yt-dlp.md for the cron PATH requirement.\n' >&2
        exit "${EXIT_INCONCLUSIVE}"
    }
}

fetch_listing() {
    # --flat-playlist lists without touching any media, so the exit-0-on-failed-
    # download trap in rules/tools/yt-dlp.md does not apply. An empty listing is
    # still checked by the caller rather than treated as an absence.
    yt-dlp --flat-playlist --no-warnings \
        --print "%(upload_date)s|%(title)s|%(url)s" \
        "${CHANNEL}/videos" 2>/dev/null || true
}

notify() {
    local hits="$1"
    if ! command -v gog >/dev/null 2>&1; then
        printf 'WARN: gog not on PATH, no notification sent.\n' >&2
        return
    fi
    printf 'The Portland Ignite recording appears to be up:\n\n%s\n\nNext steps are on issue #8 in the talk repo.\n' "${hits}" \
        | gog -a "${NOTIFY_TO}" gmail send --to "${NOTIFY_TO}" \
            --subject "Portland Ignite video is published" --body-file -
    printf 'notified %s\n' "${NOTIFY_TO}"
}

main() {
    local notify_flag="${1:-}"
    if [[ "${notify_flag}" == "-h" || "${notify_flag}" == "--help" ]]; then
        usage
        exit "${EXIT_FOUND}"
    fi
    if [[ -n "${notify_flag}" && "${notify_flag}" != "--notify" ]]; then
        printf 'unknown argument: %s\n\n' "${notify_flag}" >&2
        usage >&2
        exit "${EXIT_INCONCLUSIVE}"
    fi

    require_tool yt-dlp

    printf '=== DevOpsDays Portland channel, checked %s ===\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

    local listing
    listing="$(fetch_listing)"

    if [[ -z "${listing}" ]]; then
        printf 'INCONCLUSIVE: the channel returned no entries at all.\n'
        printf 'That is a tooling or access problem, not evidence the video is absent.\n'
        exit "${EXIT_INCONCLUSIVE}"
    fi

    local total
    total="$(printf '%s\n' "${listing}" | wc -l)"
    printf 'channel returned %s entries\n' "${total}"

    local hits
    hits="$(printf '%s\n' "${listing}" | grep -iE "${PATTERN}" | grep -E "${YEAR}" || true)"

    if [[ -z "${hits}" ]]; then
        printf 'NOT YET: no %s entry matching /%s/.\n' "${YEAR}" "${PATTERN}"
        printf 'Newest three, for context:\n'
        # head closes the pipe early, which raises SIGPIPE in printf and, under
        # `set -e` with pipefail, would abort with 141 instead of the intended
        # exit code. Slice first, then print.
        local sample
        sample="$(printf '%s\n' "${listing}" | sed -n '1,3p')"
        printf '%s\n' "${sample}" | sed 's/^/  /'
        exit "${EXIT_NOT_YET}"
    fi

    printf 'FOUND:\n'
    printf '%s\n' "${hits}" | sed 's/^/  /'

    if [[ "${notify_flag}" == "--notify" ]]; then
        notify "${hits}"
    fi
    exit "${EXIT_FOUND}"
}

main "$@"
