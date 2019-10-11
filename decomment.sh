#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-10-11 12:15:47 +0100 (Fri, 11 Oct 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
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

if [ "$()" = "<" ]; then
    if type -P decomment-xml.pl &>/dev/null; then
        decomment-xml.pl "$@"
    else
        echo "decomment-xml.pl from DevOps Perl Tools repo not found in \$PATH - ensure you have downloaded and built it before running this against XML files"
        exit 1
    fi
else
    sed 's/#.*$//; /^[[:space:]]*$/d' "$@"
fi
