#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-23 23:25:39 +0100 (Sun, 23 Aug 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/packages.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Checks a given list of Deb packages and returns those already installed

$package_args_description

Tested on Debian and Ubuntu
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<packages>"

help_usage "$@"

export DEBIAN_FRONTEND=noninteractive

process_package_args "$@" |
grep -Fx -f <(installed_debs) || :  # grep causes pipefail exit code breakages in calling code when it doesn't match
