#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-03-05 18:18:13 +0000 (Tue, 05 Mar 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

usage(){
    if [ -n "$*" ]; then
        echo "$@"
        echo
    fi
    cat <<EOF

Splits big file(s) in to \$PARTS parts (defaults to the number of CPU processors)

Useful for easy parallelizing things that don't easily lend themselves to parallelization like
anonymize.py from DevOps Python Tools which needs successive ordered anonymization rules

usage: ${0##*/} <files>

-h --help   Show usage and exit

EOF
    exit 3
}

for x in $@; do
    case $x in
        -h|--help)  usage
                    ;;
    esac
done

check_bin(){
    local bin="$1"
    if ! which $bin &>/dev/null; then
        echo "$bin command not found in \$PATH ($PATH)"
        exit 1
    fi
}
check_bin split
check_bin parallel

parts="${PARTS:-}"

if [ -z "$parts" ]; then
    if [ "$(uname -s)" = "Darwin" ]; then
        parts="$(sysctl -n hw.ncpu)"
    else
        parts="$(awk '/^processor/ {++n} END {print n+1}' /proc/cpuinfo)"
    fi
fi

for filename in $@; do
    echo "Splitting $filename in to $parts parts"
    if [ "$(uname -s)" = "Darwin" ]; then
        linecount="$(wc -l < "$filename" | awk '{print $1}')"
        parts="$(bc <<< "$linecount / $parts")"
        split -l "$parts" "$filename" "$filename."
    else
        split -d -n "1/$parts" "$filename" "$filename."
    fi
done
echo "Done"
