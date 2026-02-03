#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-23 18:32:06 +0100 (Sun, 23 Aug 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
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
Installs Yum RPM package lists if the packages aren't already installed

$package_args_description

Tested on CentOS
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<packages>"

help_usage "$@"

yum install -y xargs

process_package_args "$@" |
"$srcdir/rpms_filter_not_installed.sh" |
rpms_filter_not_provided |
xargs --no-run-if-empty "$srcdir/yum_install_packages.sh"
