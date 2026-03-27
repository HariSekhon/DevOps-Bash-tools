#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: title subtitle test message
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
Generates a temporary pop-up notification on macOS in the top right corner

If not dismissed this persists in Notification Center until cleared
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<title>] [<subtitle>] <message>"

help_usage "$@"

min_args 1 "$@"

mac_only

title=""
subtitle=""

if [ $# -gt 1 ]; then
    title="$1"
    shift || :
fi

if [ $# -gt 1 ]; then
    subtitle="$1"
    shift || :
fi

message="$*"

title="${title//\"}"
subtitle="${subtitle//\"}"
message="${message//\"}"

osascript -e "
    display notification \"$message\" with title \"$title\" subtitle \"$subtitle\"
"
