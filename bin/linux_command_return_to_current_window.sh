#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2026-05-04 14:53:49 +0200 (Mon, 04 May 2026)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
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
Runs a Linux command that opens a window and then returns to the existing window
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<command>"

help_usage "$@"

min_args 1 "$@"

current="$(xdotool getwindowfocus)"

"$@" &

sleep 0.5

xdotool windowactivate "$current"
