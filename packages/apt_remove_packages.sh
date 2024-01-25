#!/bin/sh
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-02-15 21:31:10 +0000 (Fri, 15 Feb 2019)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Remove and Purge Deb packages in a forgiving way - useful for uninstalling development packages no longer needed eg. to minimize size of Docker images

set -eu
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/ci.sh"

echo "Removing Deb Packages"

export DEBIAN_FRONTEND=noninteractive

#apt="apt"
apt="apt-get"

if ! type "$apt" >/dev/null 2>&1; then
    echo "$apt not found in \$PATH ($PATH), cannot install apt packages!"
    exit 1
fi

opts="--no-install-recommends"
if is_CI; then
    echo "running in CI quiet mode"
    opts="$opts -qq"
fi

packages=""
for arg; do
    if [ -f "$arg" ]; then
        echo "adding packages from file:  $arg"
        packages="$packages $(sed 's/#.*//;/^[[:space:]]*$$/d' "$arg")"
        echo
    else
        packages="$packages $arg"
    fi
    # uniq
    packages="$(echo "$packages" | tr ' ' ' \n' | sort -u | tr '\n' ' ')"
done

if [ -z "$packages" ]; then
    exit 0
fi

SUDO=""
# shellcheck disable=SC2039
[ "${EUID:-$(id -u)}" != 0 ] && SUDO=sudo

if [ -n "${NO_FAIL:-}" ]; then
    # shellcheck disable=SC2086
    if ! $SUDO "$apt" purge -y $packages; then
        for package in $packages; do
            $SUDO "$apt" purge -y "$package" || :
        done
    fi
else
    # shellcheck disable=SC2086
    $SUDO "$apt" purge -y $packages
fi
