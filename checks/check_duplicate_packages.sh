#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-02-27 11:49:47 +0000 (Wed, 27 Feb 2019)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Script to find duplicate RPM / Deb / Apk / Brew / Portage packages across files

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/utils.sh
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034
usage_args="[<package_list_files>]"

for x in "$@"; do
    case "$x" in
    -h|--help)  usage
                ;;
    esac
done

section "Duplicate Packages Check"

start_time="$(start_timer)"

found=0

find_dups(){
    local duplicate_packages
    # need word splitting for different files
    # shellcheck disable=SC2086
    duplicate_packages="$(sed 's/#.*//;
         s/[<>=].*//;
         s/^[[:space:]]*//;
         s/[[:space:]]*$//;
         /^[[:space:]]*$/d;' $package_files |
        sort |
        uniq -d
    )"
    while read -r package; do
        [ -n "$package" ] || continue
        # need word splitting for different files
        # shellcheck disable=SC2086
        grep "^${package}\\([[:space:]]\\|$\\)" $package_files
        ((found+=1))
    done <<< "$duplicate_packages"

}

if [ -n "$*" ]; then
    package_files="$*"
    find_dups "$package_files"
else
    found_files=0
    for x in rpm deb apk brew portage; do
        package_files="$(find . -maxdepth 3 -name "$x*-packages*.txt" | grep -v desktop || :)"
        if [ -z "$package_files" ]; then
            continue
        fi
        found_files=1
        echo "checking for duplicate $x packages" >&2
        find_dups "$package_files"
        echo
    done
    if [ $found_files -eq 0 ]; then
        #usage "No package files found, please specify explicit path to *-packages*.txt"
        warn "No package files found, please specify explicit path to *-packages*.txt"
    fi
fi

if [ $found -gt 0 ]; then
    exit 1
fi

time_taken "$start_time"
section2 "Passed - no duplicate packages found"
echo
