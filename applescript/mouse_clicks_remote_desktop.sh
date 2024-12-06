#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-12-06 10:55:58 +0700 (Fri, 06 Dec 2024)
#
#  https://github.com/HariSekhon
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
. "$srcdir/../lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Switches to Microsoft Remote Desktop, waits 10 seconds and then clicks the mouse once a minute to prevent the screensaver from coming on

Workaround to Active Directory Group Policies that don't let you disable the screensaver

Point the mouse to a safe location with no mouse click effect

Then Cmd-Tab to Terminal, run this and let it switch back to Remote Desktop to keep the session open
minute to prevent the screensaver from coming on
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

num_args 0 "$@"

export START_DELAY="${START_DELAY:-10}"
export SLEEP_SECS="${SLEEP_SECS:-60}"

if ! is_float "$START_DELAY"; then
    usage "invalid non-float '$START_DELAY' found in environment for \$START_DELAY"
fi

if ! is_float "$SLEEP_SECS"; then
    usage "invalid non-float '$SLEEP_SECS' found in environment for \$SLEEP_SECS"
fi

timestamp "Switching foreground window to Remote Desktop"
"$srcdir/set_frontmost_process.scpt" "Microsoft Remote Desktop"

exec "$srcdir/mouse_clicks.sh" -1
