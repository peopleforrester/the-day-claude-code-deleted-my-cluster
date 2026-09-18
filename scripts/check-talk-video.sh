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
# below matches the year in the video TITLE. DevOpsDays titles have carried the
# year consistently since 2016, but that is a convention, not a guarantee.
#
# Usage:
#   scripts/check-talk-video.sh            # report only
#   scripts/check-talk-video.sh --notify   # also mail Michael if it appears
#
# Install as a weekly cron (note the yt-dlp and PATH requirements):
#   17 9 * * 1 cd $HOME/repos/events/the-day-claude-code-deleted-my-cluster && \
#     scripts/check-talk-video.sh --notify >> $HOME/logs/talk-video.log 2>&1

set -uo pipefail

CHANNEL="https://www.youtube.com/channel/UCxzmx6LKP5PmcR1wVUj1dxw"
# Match loosely: organizers title these inconsistently across years.
PATTERN='claude|cluster|forrester|ignite'
YEAR='2026'
NOTIFY_TO="michaelrishiforrester@gmail.com"

command -v yt-dlp >/dev/null 2>&1 || {
    echo "FAIL: yt-dlp not on PATH. Under cron, export the full PATH; see rules/tools/yt-dlp.md."
    exit 3
}

echo "=== DevOpsDays Portland channel, checked $(date -u +%Y-%m-%dT%H:%M:%SZ) ==="

# --flat-playlist avoids touching any media. This is a listing, not a download,
# so the exit-0-on-failed-download trap in rules/tools/yt-dlp.md does not apply
# here; an empty listing is still checked explicitly below.
listing=$(yt-dlp --flat-playlist --no-warnings \
    --print "%(upload_date)s|%(title)s|%(url)s" \
    "${CHANNEL}/videos" 2>/dev/null)

if [ -z "$listing" ]; then
    echo "INCONCLUSIVE: the channel returned no entries at all."
    echo "That is a tooling or access problem, not evidence the video is absent."
    exit 2
fi

total=$(printf '%s\n' "$listing" | wc -l)
echo "channel returned $total entries"

hits=$(printf '%s\n' "$listing" | grep -iE "$PATTERN" | grep -E "^${YEAR}|${YEAR}" || true)

if [ -z "$hits" ]; then
    echo "NOT YET: no ${YEAR} entry matching /${PATTERN}/."
    echo "Newest three, for context:"
    printf '%s\n' "$listing" | head -3 | sed 's/^/  /'
    exit 1
fi

echo "FOUND:"
printf '%s\n' "$hits" | sed 's/^/  /'

if [ "${1:-}" = "--notify" ]; then
    if command -v gog >/dev/null 2>&1; then
        printf 'The Portland Ignite recording appears to be up:\n\n%s\n\nNext steps are on issue #8 in the talk repo.\n' "$hits" \
          | gog -a "$NOTIFY_TO" gmail send --to "$NOTIFY_TO" \
              --subject "Portland Ignite video is published" --body-file - \
          && echo "notified $NOTIFY_TO"
    else
        echo "WARN: gog not on PATH, no notification sent."
    fi
fi
exit 0
