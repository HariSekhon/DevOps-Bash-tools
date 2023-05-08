#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2018-01-12 19:13:34 +0000 (Fri, 12 Jan 2018)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Script to find a hanging mount point on Linux (often caused by NFS)

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
#srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage(){
    cat <<EOF

Script to find a hanging mount point by iterating over each of them in turn, printing the name before reading from them

The hanging mount point will be the one you get stuck on, so you can debug that one (usually an NFS mount point)

usage:  ${0##*/} [ --include <posix_regex> ] [ --exclude <posix_regex> ]

EOF
    exit 3
}

include_regex=".*"
exclude_regex=""

until [ $# -lt 1 ]; do
    case $1 in
        -i|--include) include_regex="$2"
                      shift
                      ;;
        -e|--exclude) exclude_regex="$2"
                      shift
                      ;;
         *) usage
            ;;
    esac
    shift
done

if [ "$(uname -s)" != "Linux" ]; then
    echo "Error: this only runs on Linux"
    exit 1
fi

if ! [ -f /proc/mounts ]; then
    echo "Error: /proc/mounts not found"
    exit 1
fi

echo "Testing listing in each mount point:"
echo
awk '{print $2}' /proc/mounts |
grep -Ev ' cgroup ' |
grep -E "$include_regex" |
# default blank here would exclude everything, switched to test within loop only if exclude_regex is not blank
#grep -Ev "$exclude_regex" |
while read -r mountpoint; do
    [ -d "$mountpoint" ] || continue
    if [ "$mountpoint"       = "/proc"  ] ||
       [ "$mountpoint"       = "/sys"   ] ||
       [ "$mountpoint"       = "/dev"   ] ||
       [ "${mountpoint:0:6}" = "/proc/" ] ||
       [ "${mountpoint:0:5}" = "/sys/"  ] ||
       [ "${mountpoint:0:5}" = "/dev/"  ]; then
        continue
    fi
    if [[ -n "$exclude_regex" && "$mountpoint" =~ $exclude_regex ]]; then
        continue
    fi
    echo -n "$mountpoint:  "
    ls -l "$mountpoint" &>/dev/null
    echo "OK"
done
echo
echo "Finished"
