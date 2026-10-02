#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2026-10-01 16:44:38 +0900 (Thu, 01 Oct 2026)
#
#  https://github.com/HariSekhon
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn
#  and optionally send me feedback
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Sleep until the given HH:MM clock time

Useful for delaying the run of a foreground terminal application to inherit your terminal's environment variables
(which may contain API keys) or interactively manage a process in your terminal,
which cannot be done with the 'at' command

I use this for my HariSekhon/Spotify-Playlists backup each night so it waits in terminal for me to arrive home
and runs it interactively to allow human gate safety approvals before Git committing any song removals from
any playlist

You could also break this down into a CI/CD process with a Human Gate approval step but that requires more
infrastructure and overhead while this is cheap and chearful like unix core utils

If running on a laptop that wakes up <grace_minutes> after the time it'll also run

Grace minutes defaults to 120 - if more than 120 minutes late script exits 1 to indicate error,
allowing you to '&&' chain or use an 'if' conditional to only run during the expected window

Example:

    ${0##*/} 23:30 && ./run_something.sh
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<HH:MM> [<grace_minutes>]"

help_usage "$@"

min_args 1 "$@"
max_args 2 "$@"

target_time="$1"
grace_mins="${2:-120}"

if ! [[ "$target_time" =~ ^([01][0-9]|2[0-3]):[0-5][0-9]$ ]]; then
    usage "invalid time '$target_time' (expected HH:MM, 00:00-23:59)"
fi

if ! [[ "$grace_mins" =~ ^[0-9]+$ ]]; then
    usage "invalid minutes '$grace_mins' (expected a non-negative integer)"
fi

target_hour="${target_time%%:*}"
target_minute="${target_time##*:}"

now_epoch="$(date '+%s')"
today="$(date '+%Y-%m-%d')"

target_time_epoch=$(gdate -d "$today $target_hour:$target_minute:00" +%s)

# if the target_time has already passed today, assume user meant tomorrow
if (( target_time_epoch <= now_epoch )); then
    target_time_epoch=$((target_time_epoch + 86400))
fi

latest_grace_epoch="$((target_time_epoch + grace_mins * 60))"

timestamp "Waiting until $target_time (up to $grace_mins minutes late)..."

while true; do
    now_epoch="$(date '+%s')"

    if (( now_epoch >= target_time_epoch )); then
        timestamp "Target time reached"
        break
    fi

    sleep_seconds="$((target_time_epoch - now_epoch))"

    # don't sleep for more than 60 seconds so that a wake from sleep
    # is detected promptly
    if (( sleep_seconds > 60 )); then
        sleep_seconds=60
    fi

    sleep "$sleep_seconds"
done

# ===================================================================
# if laptop was asleep at the target_time, start immediately on wake,
# or exit with an error to break '&&' chaining of 'if' conditional after grace_mins period late

now_epoch="$(date '+%s')"

if (( now_epoch > latest_grace_epoch )); then
    timestamp "Woke up too late"
    timestamp "Grace mins period expired at $(date -r "$latest_grace_epoch" '+%Y-%m-%d %H:%M:%S')"
    timestamp "Exiting with error exit code 1"
    exit 1
fi

timestamp "Sleep ended"
