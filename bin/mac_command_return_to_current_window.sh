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
Runs a Mac command that opens a window and then switches back to the original foreground window

You can also use the native open command:

    open --background APP

For more about the Mac open tool, see the Mac page in my Knowledge-Base repo:

    https://github.com/HariSekhon/Knowledge-Base/blob/main/mac.md#open
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<command>"

help_usage "$@"

min_args 1 "$@"

if ! is_mac; then
    die "ERROR: only supported on Mac"
fi

current="$("$srcdir/../applescript/get_frontmost_process.scpt")"

"$@" &

sleep 0.5

"$srcdir/../applescript/set_frontmost_process.scpt" "$current"
