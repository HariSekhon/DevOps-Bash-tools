#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-02-27 11:52:24 +0000 (Wed, 27 Feb 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Script to find duplicate Perl CPAN module requirements across files

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

usage(){
    if [ -n "$*" ]; then
        echo "$@"
        echo
    fi
    cat <<EOF

usage: ${0##*/} <files>

EOF
    exit 3
}

for x in $@; do
    case $x in
    -h|--help)  usage
                ;;
    esac
done

found=0

while read module; do
    grep "^$module\>" "$@"
    ((found++))
done < <(
    sed 's/#.*//;
         s/@.*//;
         s/^[[:space:]]*//;
         s/[[:space:]]*$//;
         /^[[:space:]]*$/d;' "$@" |
    sort |
    uniq -d
)

if [ $found -gt 0 ]; then
    exit 1
fi
