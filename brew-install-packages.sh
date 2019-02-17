#!/bin/sh
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-02-15 21:31:10 +0000 (Fri, 15 Feb 2019)
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

set -eu
[ -n "${DEBUG:-}" ] && set -x

if [ $# = 0 ]; then
    echo "usage: ${0##*/} <filename> <filename> ..."
    exit 1
fi

echo "Installing Mac HomeBrew Packages"

brew_packages="$(sed 's/#.*//; /^[[:space:]]*$/d' "$@")"

# Sudo is not required as running Homebrew as root is extremely dangerous and no longer supported as
# Homebrew does not drop privileges on installation you would be giving all build scripts full access to your system

if [ -n "${NO_UPDATE:-}" ]; then
    if ! brew update; then
        if [ -n "${NO_FAIL:-}" ]; then
            :
        else
            exit 1
        fi
    fi
fi

if [ -n "${NO_FAIL:-}" ]; then
    for package in $apk_packages; do
        brew install "$package" || :
    done
else
    brew install $apk_packages
fi
