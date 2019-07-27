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

# Install Apk packages in a forgiving way - useful for install Perl CPAN and Python PyPI modules that may or may not be available
#
# combine with later use of the following scripts to only build packages that aren't available in the Linux distribution:
#
# perl_cpanm_install_if_absent.sh
# python_pip_install_if_absent.sh

set -eu
[ -n "${DEBUG:-}" ] && set -x

echo "Installing Apk Packages listed in file(s): $*"

apk_packages="$(cat "$@" | sed 's/#.*//; /^[[:space:]]*$/d' | sort -u)"

if [ -z "$apk_packages" ]; then
    exit 0
fi

SUDO=""
# $EUID isn't available in /bin/sh in Alpine
# shellcheck disable=SC2039
[ "${EUID:-$(id -u)}" != 0 ] && SUDO=sudo

[ -n "${NO_UPDATE:-}" ] || $SUDO apk update

if [ -n "${NO_FAIL:-}" ]; then
    for package in $apk_packages; do
        $SUDO apk add "$package" || :
    done
else
    # shellcheck disable=SC2086
    $SUDO apk add $apk_packages
fi
