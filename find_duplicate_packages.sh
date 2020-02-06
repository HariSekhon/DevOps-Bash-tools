#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-02-27 11:49:47 +0000 (Wed, 27 Feb 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Script to find duplicate RPM / Deb / Apk / Brew / Portage packages across files

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "${BASH_SOURCE[0]}")"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034
usage_args="[<package_list_files>]"

for x in "$@"; do
    case "$x" in
    -h|--help)  usage
                ;;
    esac
done

find_dups(){
    local found=0
    # need word splitting for different files
    # shellcheck disable=SC2086
    sed 's/#.*//;
         s/[<>=].*//;
         s/^[[:space:]]*//;
         s/[[:space:]]*$//;
         /^[[:space:]]*$/d;' $requirements_files |
    sort |
    uniq -d |
    while read -r module ; do
        # need word splitting for different files
        # shellcheck disable=SC2086
        grep "^${module}" $requirements_files
        ((found + 1))
    done

    if [ $found -gt 0 ]; then
        exit 1
    fi
}

if [ -n "$*" ]; then
    requirements_files="$*"
    find_dups "$requirements_files"
else
    found_files=0
    for x in rpm deb apk brew portage; do
        echo "checking for duplicate $x packages"
        requirements_files="$(find . -maxdepth 3 -name "$x*-packages*.txt")"
        if [ -z "$requirements_files" ]; then
            continue
        fi
        found_files=1
        find_dups "$requirements_files"
    done
    if [ $found_files -eq 0 ]; then
        usage "No package files found, please specify explicit path to *-packages*.txt"
    fi
fi
