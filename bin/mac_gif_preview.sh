#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-02-19 17:13:31 +0700 (Wed, 19 Feb 2025)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
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
Opens Gif in the Mac Finder file viewer preview because the Preview app doesn't show the animation

You can also open it in a web browser to render the animation if you prefer:

    open -a Safari \"\$file\"

    open -a 'Google Chrome' \"\$file\"
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<file.gif>"

help_usage "$@"

num_args 1 "$@"

file="$1"

open -R "$file"

SLEEP_SECS=0.5

sleep "$SLEEP_SECS"

applescript="$srcdir/../applescript"

timestamp "Switching to Finder"
"$applescript/set_frontmost_process.scpt" Finder

sleep "$SLEEP_SECS"

timestamp "Checking Finder is the frontmost process"
if [ "$("$applescript/get_frontmost_process.scpt")" != Finder ]; then
    die "Failed to switch to Finder - not the frontmost process"
fi

# https://eastmanreference.com/complete-list-of-applescript-key-codes

export START_DELAY=0  # don't wait before sending keystrokes

echo >&2
"$applescript/keystrokes.sh" 1 49  # 1 x space
