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

# Install Deb packages in a forgiving way - useful for install Perl CPAN and Python PyPI modules that may or may not be available
#
# combine with later use of the following scripts to only build packages that aren't available in the Linux distribution:
#
# perl_cpanm_install_if_absent.sh
# python_pip_install_if_absent.sh

set -eu
[ -n "${DEBUG:-}" ] && set -x

echo "Installing Deb Packages listed in file(s): $*"

export DEBIAN_FRONTEND=noninteractive

opts="--no-install-recommends"
if [ -n "${TRAVIS:-}" ]; then
    echo "running in quiet mode"
    opts="$opts -qq"
fi

deb_packages="$(cat "$@" | sed 's/#.*//; /^[[:space:]]*$/d' | sort -u)"

if [ -z "$deb_packages" ]; then
    exit 0
fi

SUDO=""
[ "${EUID:-$(id -u)}" != 0 ] && SUDO=sudo

[ -n "${NO_UPDATE:-}" ] || $SUDO apt-get $opts update

if [ -n "${NO_FAIL:-}" ]; then
    for package in $deb_packages; do
        $SUDO apt-get install -y $opts "$package" || :
    done
else
    $SUDO apt-get install -y $opts $deb_packages
fi
