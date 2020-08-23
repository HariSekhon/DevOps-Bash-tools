#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-23 17:28:41 +0100 (Sun, 23 Aug 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Caveat: doesn't catch metapackages eg. vim on centos is resolved to vim-enhanced and doesn't match to prevent trying to install again

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

packages=("$@")

check_bin(){
    type -P "$@" &>/dev/null
}

check_packages_list(){
    tr ' ' '\n' <<< "${packages[*]}" | grep -vFx -f <("$@")
}

if check_bin apk; then
    check_packages_list apk info
elif check_bin apt-get dpkg; then
    #check_packages dpkg -s

    # want dollar passed as-is in single quotes
    # shellcheck disable=SC2016
    check_packages_list dpkg-query -W -f '${binary:Package}\n'
elif check_bin yum rpm; then
    #check_packages rpm -q

    check_packages_list rpm -qa --queryformat '%{RPMTAG_NAME}\n' |
    while read -r package; do
        # accounts for vim being provided by vim-enhanced, so we don't try to install the metapackage again and again
        rpm -q --queryformat '%{RPMTAG_NAME}\n' --whatprovides "$package" &>/dev/null ||
        echo "$package"
    done
elif check_bin brew; then
    check_packages_list brew list
else
    echo "Unsupported OS / Package Manager"
    exit 1
fi |
"$srcdir/install_packages.sh"
