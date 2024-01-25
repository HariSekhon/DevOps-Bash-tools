#!/bin/sh
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-02-21 20:41:52 +0000 (Fri, 21 Feb 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Had to do this in /bin/sh not bash so that it can be used on bootstrapping Alpine builds

set -eu
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

# bash only
#if [[ "${1:-}" =~ ^[[:digit:]]+$ ]]; then
if echo "${1:-}" | grep -Eq '^[[:digit:]]+$'; then
    tries="$1"
    shift
fi

if [ $# -lt 1 ]; then
    usage
fi

set +e
# {1..$tries} doesn't work and `seq` is a needless fork
# bash only
#for ((i=0; i < tries; i++)); do
for _ in $(seq "$tries"); do
    eval "$@"
    result=$?
    if [ $result -eq 0 ]; then
        break
    fi
done
exit "$result"
