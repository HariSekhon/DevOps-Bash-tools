#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-02-21 20:41:52 +0000 (Fri, 21 Feb 2020)
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

tries="${TRIES:-3}"

usage(){
    cat <<EOF

usage: ${0##*/} [<num_tries>] <command>

EOF
    exit 3
}

for arg; do
    case "$arg" in
        --help)  usage
                 ;;
    esac
done

if [[ "${1:-}" =~ ^[[:digit:]]+$ ]]; then
    tries="$1"
    shift
fi

if [ $# -lt 1 ]; then
    usage
fi

set +eo pipefail
# {1..$tries} doesn't work and `seq` is a needless fork
for ((i=0; i < tries; i++)); do
    eval "$@"
    result=$?
    if [ $result -eq 0 ]; then
        break
    fi
done
exit $result
