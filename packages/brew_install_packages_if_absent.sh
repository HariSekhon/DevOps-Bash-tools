#!/usr/bin/env bash
#  shellcheck disable=SC2086
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-23 19:03:51 +0100 (Sun, 23 Aug 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Mac OSX - HomeBrew install packages in a forgiving way

set -eu #o pipefail  # undefined in /bin/sh
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/packages.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Installs Mac Homebrew package lists if the packages aren't already installed

$package_args_description

Tested on macOS
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<packages>"

help_usage "$@"

process_package_args "$@" |
"$srcdir/brew_filter_not_installed.sh" |
gxargs --no-run-if-empty "$srcdir/brew_install_packages.sh"
