#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-10-27 12:11:13 +0100 (Thu, 27 Oct 2022)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
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
On Mac deletes all routes relating to a given network interface

Useful to clear stale route entries left by vpn clients such as AWS Client VPN that may interfere with networking or reconnections

(You may also need to restart your wifi after disconnecting AWS VPN Client - appears to be buggy behaviour)
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<interface>"

help_usage "$@"

min_args 1 "$@"

interface="$1"

is_mac || usage "ERROR: this script is only designed to run on Mac"

netstat -rn |
awk "/$interface/{print \$1}" |
while read -r net; do
    # defined in lib/utils.sh
    # shellcheck disable=SC2154
    $sudo route delete -net "$net" -ifp "$interface"
done
