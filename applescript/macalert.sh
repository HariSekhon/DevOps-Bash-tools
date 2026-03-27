#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: title test message
#
#  Author: Hari Sekhon
#  Date: 2026-03-27 17:12:09 -0500 (Fri, 27 Mar 2026)
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
Generates a persistent pop-up alert in the middle of the screen on macOS

Requires the OK button to be clicked to dismiss it
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<title>] <message>"

help_usage "$@"

min_args 1 "$@"

mac_only

title=""

if [ $# -gt 1 ]; then
    title="$1"
    shift || :
fi

message="$*"

title="${title//\"}"
message="${message//\"}"

osascript -e "
    display alert \"$title\" message \"$message\" as informational
"
