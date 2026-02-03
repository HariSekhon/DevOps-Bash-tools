#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2026-02-03 00:01:41 -0300 (Tue, 03 Feb 2026)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn
#  and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -eu
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/packages.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Upgrades Yum RPM package lists if the packages are outdated

$package_args_description

Tested on CentOS
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<packages>"

help_usage "$@"

# get xargs if it's not installed since we call it below in the shell pipeline
rpm -q findutils &>/dev/null ||
yum install -y findutils

# quicker and simpler to just let yum/dnf determine that it's not already installed
#
# dnf outputs something like:
#
#   No match for argument: wget
#   No match for argument: nonexistentpackage
#
# regardless of whether there is a potential package upsteam like wget, or not like nonexistentpackage
#
#upgradeable_packages="$(yum check-update)"

process_package_args "$@" |
#while read -r package; do
#    if echo "$upgradeable_packages" | grep -Eq "^$package(.|[[:space:]])"; then
#        echo "$package"
#    fi
#done |
xargs --no-run-if-empty yum upgrade -y
