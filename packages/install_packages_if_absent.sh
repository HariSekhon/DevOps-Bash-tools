#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-23 17:28:41 +0100 (Sun, 23 Aug 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Caveat: doesn't catch metapackages eg. vim on centos is resolved to vim-enhanced and doesn't match to prevent trying to install again

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

packages=("$@")

check_bin(){
    type -P "$@" &>/dev/null
}

if check_bin apk; then
    "$srcdir/apk_install_packages_if_absent.sh" "${packages[@]}"
elif check_bin apt-get dpkg; then
    "$srcdir/apt_install_packages_if_absent.sh" "${packages[@]}"
elif check_bin yum rpm; then
    "$srcdir/yum_install_packages_if_absent.sh" "${packages[@]}"
elif check_bin brew; then
    "$srcdir/brew_install_packages_if_absent.sh" "${packages[@]}"
else
    echo "Unsupported OS / Package Manager"
    exit 1
fi
