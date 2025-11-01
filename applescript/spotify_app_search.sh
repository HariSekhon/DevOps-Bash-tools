#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-11-01 23:34:33 +0300 (Sat, 01 Nov 2025)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn
#  and optionally send me feedback to help steer this or other code I publish
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
Runs a search in the Spotify App on Mac using Applescript
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<search terms>"

help_usage "$@"

min_args 1 "$@"

mac_only

query="$*"

timestamp "Telling Spotify app to search for: $query"

osascript \
        -e 'tell application "Spotify" to activate' \
        -e 'tell application "System Events" to keystroke "l" using {command down}' \
        -e 'delay 0.2' \
        -e "tell application \"System Events\" to keystroke \"$query\" & return"
