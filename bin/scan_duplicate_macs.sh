#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-03-14 18:41:35 +0000 (Thu, 14 Mar 2019)
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

usage(){
    if [ -n "$*" ]; then
        echo "$@"
        echo
    fi
    cat <<EOF

Scans locally attached networks and prints duplicate MAC addresses

Useful for finding duplicate MACs and also finding hosts behind a VIP or similar floating address (VRRP, HSRP)

Uses fping to ping all addresses on all local subnets and then checks the local arp cache

Caveat: won't find a VIP on the local host this script is run on

usage: ${0##*/}

EOF
    exit 3
}

until [ $# -lt 1 ]; do
    case $1 in
    -h|--help)  usage
                ;;
            *)  usage "unknown argument: $1"
                ;;
    esac
    shift || :
done

if [ -z "${NOSCAN:-}" ]; then
    if [ "$(uname -s)" = "Darwin" ]; then
        networks="$(netstat -rn | awk '/link#/{print $1}' | grep -e '[[:digit:]]\+\.[[:digit:]]\+\.[[:digit:]]\+\.[[:digit:]]\+')"
    else # assume Linux
        networks="$(ip addr | awk '/inet /{print $2}' | grep -v '^127\.')"
    fi

    for network in $networks; do
        echo "scanning network $network..." >&2
        fping -q -r 0 -c 1 -B 1 -g "$network" >&2 || :
    done
fi

# Linux
#arp -e |
# BSD - more portable, both Linux and Mac support this
arp -a |
# incomplete seems to only appear on arp on Linux, for both -a and -e formats
# Linux arp -e
#awk '!/incomplete/{print $3}' |
# BSD arp -a (works on Linux too)
awk '!/incomplete/{print $4}' |
grep -vi "ff:ff:ff:ff:ff:ff" |
sort |
uniq -d |
while read -r mac; do
    # Linux
    #arp -e |
    # BSD - more portable, both Linux and Mac support this
    arp -a |
    grep "$mac"
done
