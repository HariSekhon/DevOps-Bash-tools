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

# Install Apk packages in a forgiving way - useful for install Perl CPAN and Python PyPI modules that may or may not be available (will retry cpanm / pip later if they are not found)

set -eu
[ -n "${DEBUG:-}" ] && set -x

echo "Installing Apk Packages"

apk_packages="$(cat "$@" | sed 's/#.*//; /^[[:space:]]*$/d' | sort -u)"

SUDO=""
# $EUID isn't available in /bin/sh in Alpine
[ "${EUID:-$(id -u)}" != 0 ] && SUDO=sudo

[ -n "${NO_UPDATE:-}" ] || apk update

if [ -n "${NO_FAIL:-}" ]; then
    for package in $apk_packages; do
        $SUDO apk add "$package" || :
    done
else
    $SUDO apk add $apk_packages
fi
