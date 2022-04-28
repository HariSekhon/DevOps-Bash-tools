#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-10-11 12:15:47 +0100 (Fri, 11 Oct 2019)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Prints files without comments

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

usage(){
    echo "usage: ${##*/} <files>"
    exit 3
}

for arg; do
    case "$arg" in
        -*)     usage
                ;;
    esac
done

stdin=""
if [ $# -eq 0 ]; then
    # slurping is not memory efficient, not suitable for large files, but is the only way to be able to
    # backtracking testing heads for type of decommenting and still retain full data for processing
    stdin="$(cat)"
fi

if [ "$(head -n1 "$@" <<< "$stdin" | cut -c 1)" = "<" ]; then
    if type -P decomment-xml.pl &>/dev/null; then
        decomment-xml.pl "$@" <<< "$stdin"
    else
        echo "ERROR: decomment-xml.pl from DevOps Perl Tools repo not found in \$PATH - ensure you have downloaded and built it before running this against XML files" >&2
        exit 1
    fi
elif [ "$(head -n1 "$@" <<< "$stdin" | cut -f 1-2)" = "--" ]; then
    sed 's/--.*$//; /^[[:space:]]*$/d' "$@" <<< "$stdin"
else
    sed 's/#.*$//;
         s/^[[:space:]]*\/\/.*$//;
         s/[[:space:]]\/\/.*$//;
        /^[[:space:]]*$/d' "$@" <<< "$stdin"
fi
