#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-09-15 09:59:01 +0100 (Sun, 15 Sep 2019)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Returns the first argument that is found as an executable in the $PATH
#
# Useful for Macs to find where libraries executable scripts like fatpacks are, which may get installed locally in $HOME/perl5/bin to avoid Mac OS X System Integrity Protection

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/utils.sh
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Find where one or more CLI programs are installed by searching all the perl library locations

Especially useful when perl tools get installed to places not in your \$PATH - where the 'which' command can't help
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<program> [<program2> <program3> ...]"

help_usage "$@"

min_args 1 "$@"

perl="${PERL:-perl}"

perl_path=""

while read -r path; do
    bin="${path%/lib/perl*/site-packages*}/bin"
    if [ -d "$bin" ]; then
        perl_path="$perl_path:$bin"
    fi
done < <("$perl" -e 'print join("\n", @INC);')

if [ -d ~/perl5/bin ]; then
    perl_path="$perl_path:"~/perl5/bin
fi

export PATH="$perl_path:$PATH"
set +o pipefail
found="$(type -P "$@" | head -n 1)"
set -o pipefail

if [ -n "$found" ]; then
    echo "$found"
else
    echo "no perl executable was found matching any of: $*" >&2
    echo "\$PATH searched was: $PATH" >&2
    if is_CI; then
        echo
        echo "running in CI detected, attempting to search all paths" >&2
        for x in "$@"; do
            echo "searching for $x:" >&2
            find / -type f -name "$x" 2>/dev/null || :
        done
    fi
    exit 1
fi
