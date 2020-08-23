#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-23 18:32:06 +0100 (Sun, 23 Aug 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -eu
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "${BASH_SOURCE[0]}")"

usage(){
    echo "Installs Yum RPM package lists if the packages aren't already instealled"
    echo
    echo "Takes a list of yum packages as arguments or via stdin, and for any arguments that are plaintext files, reads the packages from those given files (one package per line)"
    echo
    echo "usage: ${0##*/} <list_of_packages>"
    echo
    exit 3
}

for arg; do
    case "$arg" in
        -*) usage
            ;;
    esac
done

packages=""

process_args(){
    for arg; do
        if [ -f "$arg" ]; then
            echo "adding packages from file:  $arg"
            packages="$packages $(sed 's/#.*//;/^[[:space:]]*$$/d' "$arg")"
            echo
        else
            packages="$packages $arg"
        fi
        # uniq
    done
}

if [ -n "${*:-}" ]; then
    process_args "$@"
else
    # shellcheck disable=SC2046
    process_args $(cat)
fi

tr ' ' '\n' <<< "${packages[*]}" |
grep -vFx -f <(rpm -qa --queryformat '%{RPMTAG_NAME}\n') |
while read -r package; do
    # accounts for vim being provided by vim-enhanced, so we don't try to install the metapackage again and again
    rpm -q --queryformat '%{RPMTAG_NAME}\n' --whatprovides "$package" &>/dev/null ||
    echo "$package"
done |
xargs --no-run-if-empty "$srcdir/yum_install_packages.sh"
