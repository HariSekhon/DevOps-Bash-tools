#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-24 00:42:27 +0100 (Mon, 24 Aug 2020)
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

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC1090
. "$srcdir/lib/packages.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Checks a given list of Mac Homebrew packages and returns those already installed

$package_args_description

Support TAP=1 or CASK=1 environment variables for checking taps or casks respectively

Tested on Mac Homebrew
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<packages>"

help_usage "$@"

# process_package_args requires much more specific env var to disambiguate
HOMEBREW_PACKAGES_TAP="${TAP:-}"

process_package_args "$@" |
if [ -n "${HOMEBREW_PACKAGES_TAP:-}" ]; then
    if [ -n "${NO_FAIL:-}" ]; then
        set +e
    fi
    installed_packages="$(brew list)"
    while read -r tap package; do
        set +e  # grep causes pipefail exit code breakages in calling code when it doesn't match
        grep -Fxq "$package" <<< "$installed_packages" &&
        echo "$tap $package"
    done
else
    # do not quote cask, blank quotes break shells and there will never be any token splitting anyway
    # shellcheck disable=SC2046
    tr ' ' '\n' |
    grep -Fx -f <(brew $([ -z "${CASK:-}" ] || echo cask) list) || :  # grep causes pipefail exit code breakages in calling when it doesn't match
fi
