#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-08-08 16:16:51 +0300 (Thu, 08 Aug 2024)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
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
Finds which Homebrew package owns a given file on Mac

Brew doesn't have a command to do this

First checks if the argument is a binary on the \$PATH, and if so attempts to find it in the Homebrew base Cellar

If it is it does a cheap parse and print of the package name

Does the same for NodeJS modules under Homebrew's lib/node_modules/

If it cannot find it the cheap way in those directories then prints a warning
and continues to iterates all packages one by one to find it, using the argument as a grep ERE regex

This is a very expensive O(n) operation and should be a last resort!
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<filename>"

help_usage "$@"

num_args 1 "$@"

executable_or_regex="$1"

# must not has a trailing slash for later regex matching which appends a slash
brew_basedir="/opt/homebrew"

path="$(which "$executable_or_regex" 2>/dev/null || :)"
if [ -n "$path" ]; then
    absolute_path="$(greadlink -f "$path")"

    if [[ "$absolute_path" =~ ^$brew_basedir/Cellar/ ]]; then
        # false positive, this correctly interpolates in Bash on Mac
        # shellcheck disable=SC2295
        package="${absolute_path##${brew_basedir}/Cellar/}"
        package="${package%%/*}"
        if [ -n "$package" ]; then
            echo "$package"
            exit 0
        fi
    fi

    if [[ "$absolute_path" =~ ^$brew_basedir/lib/node_modules/ ]]; then
        # false positive, this correctly interpolates in Bash on Mac
        # shellcheck disable=SC2295
        package="${absolute_path##${brew_basedir}/lib/node_modules/}"
        package="${package%%/*}"
        if [ -n "$package" ]; then
            echo "NodeJS package: $package"
            exit 0
        fi
    fi

fi

warn "failed to find '$executable_or_regex' as a binary in the Homebrew Cellar"
warn "now proceeding to a very slow expensive iterative search of every installed brew package"

brew list |
while read -r package; do
    # trade a small amount of RAM to detect when this command gets a Control-C
    # so that we don't have to keep hitting Control-C to break execution of this script
    # false positive - actually breaks out of the loop in Bash on Mac
    # shellcheck disable=SC2106
    package_contents="$(brew list "$package" || break)"
    if grep -Eq "$executable_or_regex" <<< "$package_contents"; then
        echo "$package"
    fi
done
