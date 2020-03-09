#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-09 23:35:44 +0000 (Mon, 09 Mar 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#. "$srcdir/lib/utils.sh"

if type -P apk &>/dev/null; then
    "$srcdir/apk_install_packages.sh" "$@"
elif type -P apt-get &>/dev/null; then
    "$srcdir/apt_install_packages.sh" "$@"
elif type -P yum &>/dev/null; then
    "$srcdir/yum_install_packages.sh" "$@"
elif type -P brew &>/dev/null; then
    "$srcdir/brew_install_packages.sh" "$@"
else
    echo "Unsupported OS / Package Manager"
    exit 1
fi
