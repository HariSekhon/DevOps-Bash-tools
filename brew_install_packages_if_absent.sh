#!/usr/bin/env bash
#  shellcheck disable=SC2086
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-23 19:03:51 +0100 (Sun, 23 Aug 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Mac OSX - HomeBrew install packages in a forgiving way

set -eu #o pipefail  # undefined in /bin/sh
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "${BASH_SOURCE[0]}")"

usage(){
    echo "Installs Mac Homebrew package lists if the packages aren't already installed"
    echo
    echo "Takes a list of yum packages as arguments or via stdin, and for any arguments that are plaintext files, reads the packages from those given files (one package per line)"
    echo
    echo "usage: ${0##*} <list_of_packages>"
    echo
    exit 3
}

for x in "$@"; do
    case "$x" in
        -*) usage
            ;;
    esac
done

packages=""

process_args(){
    for arg in "$@"; do
        if [ -f "$arg" ] && file "$arg" | grep -q ASCII; then
            echo "adding packages from file:  $arg"
            packages="$packages $(sed 's/#.*//;/^[[:space:]]*$$/d' "$arg")"
            echo
        else
            packages="$packages $arg"
        fi
        if [ -z "${TAP:-}" ]; then
            # uniq
            packages="$(echo "$packages" | tr ' ' ' \n' | sort -u | tr '\n' ' ')"
        fi
    done
}

if [ -n "${*:-}" ]; then
    process_args "$@"
else
    # shellcheck disable=SC2046
    process_args $(cat)
fi

if [ -n "${TAP:-}" ]; then
    # convert to array
    # need splitting
    # shellcheck disable=SC2206
    packages_array=($packages)
    if [ -n "${NO_FAIL:-}" ]; then
        set +e
    fi
    installed_packages="$(brew list)"
    for((i=0; i < ${#packages_array[@]}; i+=2)); do
        tap="${packages_array[$i]}"
        package="${packages_array[(($i+1))]}"
        grep -Fxq "$package" <<< "$installed_packages" ||
        echo "$tap $package"
    done
else
    # do not quote cask, blank quotes break shells and there will never be any token splitting anyway
    # shellcheck disable=SC2046
    tr ' ' '\n' <<< "${packages[*]}" |
    grep -vFx -f <(brew $([ -z "${CASK:-}" ] || echo cask) list)
fi |
sort -u |
grep -v '^[[:space:]]*$' |
gxargs --no-run-if-empty "$srcdir/brew_install_packages.sh"
