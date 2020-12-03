#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-10-23 10:37:20 +0100 (Wed, 23 Oct 2019)
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
srcdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

npm="${NPM:-npm}"

usage(){
    echo "Installs NodeJS NPM packages not already installed"
    echo
    echo "Leverages adjacent nodejs_npm_install.sh which will automatically set to install globally if run as root"
    echo
    echo "Takes a list of npm packages as arguments or .txt files containing lists of packages (one per line)"
    echo
    echo "usage: ${0##*} <list_of_packages>"
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
    done
}

if [ $# -gt 0 ]; then
    process_args "$@"
else
    # shellcheck disable=SC2046
    process_args $(cat)
fi

#if [ -z "${packages// }" ]; then
#    usage
#fi

packages="$(tr ' ' ' \n' <<< "$packages" | sort -u | tr '\n' ' ')"

echo "Installing NodeJS NPM packages that are not already installed"
echo

#installed_packages="$(npm_config_parseable=true $npm list 2>/dev/null | tail -n +2 | sed 's,.*/,,')"

for package in $packages; do
    #if grep -Fxq "$package" <<< "$installed_packages"; then
    # less efficient than above but more likely to not try to re-install packages
    set +o pipefail
    if npm_config_parseable=true $npm list 2>/dev/null |
        tail -n +2 |
        sed 's,.*/,,' |
        grep -Fxq "$package"; then
        echo "nodejs npm package '$package' already installed, skipping..."
    else
        echo "installing nodejs npm package '$package'"
        echo
        "$srcdir/nodejs_npm_install.sh" "$package"
    fi
done
