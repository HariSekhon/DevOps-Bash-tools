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

# Install Deb packages in a forgiving way - useful for install Perl CPAN and Python PyPI modules that may or may not be available (will retry cpanm / pip later if they are not found)

set -eu
[ -n "${DEBUG:-}" ] && set -x

if [ $# = 0 ]; then
    echo "usage: ${0##*/} <filename> <filename> ..."
    exit 1
fi

echo "Installing Deb Packages"

deb_packages="$(sed 's/#.*//; /^[[:space:]]*$/d' "$@")"

SUDO=""
[ "${EUID:-$(id -u)}" != 0 ] && SUDO=sudo

[ -n "${NO_UPDATE:-}" ] || $SUDO apt-get update

if [ -n "${NOFAIL:-}" -o -n "${NO_FAIL:-}" ]; then
    for package in $deb_packages; do
        $SUDO apt-get install -y "$package" || :
    done
else
    $SUDO apt-get install -y $deb_packages
fi
