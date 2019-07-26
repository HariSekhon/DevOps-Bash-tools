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

# Remove RPM packages in a forgiving way - useful for uninstalling development packages no longer needed eg. to minimize size of Docker images

set -eu
[ -n "${DEBUG:-}" ] && set -x

echo "Removing RPM Packages"

rpm_packages="$(cat "$@" | sed 's/#.*//; /^[[:space:]]*$/d' | sort -u)"

if [ -z "$rpm_packages" ]; then
    exit 0
fi

SUDO=""
[ "${EUID:-$(id -u)}" != 0 ] && SUDO=sudo

if [ -n "${NO_FAIL:-}" ]; then
    if ! $SUDO yum remove -y $rpm_packages; then
        for package in $rpm_packages; do
            if rpm -q "$package"; then
                $SUDO yum remove -y "$package" || :
            fi
        done
    fi
else
    # must install separately to check install succeeded because yum install returns 0 when some packages installed and others didn't
    for package in $rpm_packages; do
        rpm -q "$package" || $SUDO yum remove -y "$package"
    done
fi
