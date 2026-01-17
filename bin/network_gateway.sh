#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2026-01-17 01:35:17 -0500 (Sat, 17 Jan 2026)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback
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
Returns the network gateway in as reliable a way as we can on both Linux and Mac

Designed to make writing other scripts easier
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

no_more_args "$@"

if type -P ip &>/dev/null; then
    ip route show default 2>/dev/null |
    awk '{print $3; exit}'
# Mac's route command is different, this will only work on Linux
#elif type -P route &>/dev/null; then
#    route -n 2>/dev/null |
#    awk '$1 == "0.0.0.0" {print $2; exit}'
elif type -P netstat &>/dev/null; then
    netstat -rn 2>/dev/null |
    awk '
        $1 == "Internet:" { inet = 1; next }
        $1 == "Internet6:" { inet = 0 }
        inet && ($1 == "default" || $1 == "0.0.0.0") && $2 ~ /^[0-9.]+$/ {
            print $2
            exit
        }
    '
else
    die "Failed to get network gateway"
fi
