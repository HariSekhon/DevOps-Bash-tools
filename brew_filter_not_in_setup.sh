#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: vim bash git
#
#  Author: Hari Sekhon
#  Date: 2020-08-24 12:12:43 +0100 (Mon, 24 Aug 2020)
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
Checks a given list of Mac Homebrew packages and returns those that are not recorded in setup/brew-packages-*.txt

$package_args_description

Supports TAP=1 environment variables for checking taps list instead

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
    while read -r tap package; do
        grep -Eq "^#?${tap}[[:space:]]+$package$" <(sed 's/#.*//; /^[[:digit:]]*$/d' "$srcdir/setup/"brew-packages*taps.txt) ||
        echo "$tap $package"
    done
else
    # do not quote cask, blank quotes break shells and there will never be any token splitting anyway
    # shellcheck disable=SC2046
    tr ' ' '\n' |
    # Mac's grep is buggy, doesn't matches utimer unless sort -r to try it before '^r$' - but then gives false positives on other packages
    #grep -vFx -f <(sed 's/#.*//; s/^[[:space:]]*//; s/[[:space:]]*$//; /^[[:space:]]*$/d' "$srcdir/setup/"brew-packages*.txt | sort)
    command ggrep -vFx -f <(sed 's/#.*//; s/^[[:space:]]*//; s/[[:space:]]*$//; /^[[:space:]]*$/d' "$srcdir/setup/"brew-packages*.txt) |
    while read -r package; do
        grep -Eqi "^#${package}([[:space:]]|$)" "$srcdir/setup/"brew-packages*.txt || echo "$package"
    done |
    sort -u
fi
