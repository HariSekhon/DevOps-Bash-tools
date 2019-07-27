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

# Remove and Purge Deb packages in a forgiving way - useful for uninstalling development packages no longer needed eg. to minimize size of Docker images

set -eu
[ -n "${DEBUG:-}" ] && set -x

echo "Removing Deb Packages"

export DEBIAN_FRONTEND=noninteractive

deb_packages="$(cat "$@" | sed 's/#.*//; /^[[:space:]]*$/d' | sort -u)"

if [ -z "$deb_packages" ]; then
    exit 0
fi

SUDO=""
# shellcheck disable=SC2039
[ "${EUID:-$(id -u)}" != 0 ] && SUDO=sudo

if [ -n "${NO_FAIL:-}" ]; then
    # shellcheck disable=SC2086
    if ! $SUDO apt-get purge -y $deb_packages; then
        for package in $deb_packages; do
            $SUDO apt-get purge -y "$package" || :
        done
    fi
else
    # shellcheck disable=SC2086
    $SUDO apt-get purge -y $deb_packages
fi
