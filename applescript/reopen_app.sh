#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: Shazam
#
#  Author: Hari Sekhon
#  Date: 2025-11-02 00:44:40 +0300 (Sun, 02 Nov 2025)
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
Uses Applescript to quit and re-open a given application

Written to relaunch Shazam after deleting tracks from its DB using adjacent script to reflect the changes
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<app>"

help_usage "$@"

num_args 1 "$@"

app="$1"

mac_only

timestamp "Quitting and re-opening app: $app"

osascript <<EOF
    tell application "$app" to quit
    delay 1
    tell application "$app" to activate
EOF
