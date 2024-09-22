#!/bin/sh
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-09 23:35:44 +0000 (Mon, 09 Mar 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -eu #o pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

check_bin(){
    command -v "$1" >/dev/null 2>/dev/null
}

if check_bin apk; then
    "$srcdir/apk_install_packages.sh" "$@"
elif check_bin apt-get; then
    "$srcdir/apt_install_packages.sh" "$@"
elif check_bin yum; then
    "$srcdir/yum_install_packages.sh" "$@"
elif check_bin brew; then
    "$srcdir/brew_install_packages.sh" "$@"
else
    echo "ERROR: No recognized package manager found to install packages with"
    exit 1
fi
