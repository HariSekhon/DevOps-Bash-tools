#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2026-02-02 23:48:50 -0300 (Mon, 02 Feb 2026)
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
Upgrades Debian / Ubuntu deb package lists if the packages are outdated

Refuses to upgrade/install packages which aren't already installed

$package_args_description

Tested on Debian with apt
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<packages>"

help_usage "$@"

export DEBIAN_FRONTEND=noninteractive

apt update

# unlike other distros, it's faster and easier to just run the upgrade on the packages and let apt figure it out
#upgradeable_packages="$(apt list --upgradable)"

process_package_args "$@" |
#while read -r package; do
#    if echo "$upgradeable_packages" | grep -Eq "^$package(/|[[:space:]])"; then
#        echo "$package"
#    fi
#done |
xargs --no-run-if-empty apt install --only-upgrade -y
