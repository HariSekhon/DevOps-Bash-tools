#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-27 21:54:59 +0100 (Thu, 27 Aug 2020)
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

# shellcheck disable=SC2034,SC2154
usage_description="
Shows all outdated Homebrew packages and prompts to upgrade them
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

timestamp "updating Homebrew's package list"

brew update

echo

timestamp "Listing outdated brew packages"

echo

brew outdated

echo

read -r -p "Continue? (Y/n) " answer

shopt -s nocasematch
if ! [[ "$answer" =~ ^(y|yes)?$ ]]; then
    exit 1
fi

echo

timestamp "Upgrading brew packages"

brew upgrade

echo

timestamp "Cleaning up (removing cached downloads)"

echo

# lots of 'Warning: Skipping <name>: most recent version <x.y.z> not installed'
brew cleanup -s 2>/dev/null || :
