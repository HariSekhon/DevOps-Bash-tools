#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-11-19 19:44:49 +0400 (Tue, 19 Nov 2024)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
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
Recurses a given directory tree or \$PWD, finding all Javascript files and validating them using EsLint
"

help_usage "$@"

directory="${1:-.}"
shift ||:

files="$(find "$directory" -iname '*.js')"

if [ -z "$files" ]; then
    # this trick allows importing or calling as script
    # shellcheck disable=SC2317
    return 0 &>/dev/null || :
    # shellcheck disable=SC2317
    exit 0
fi

section "E s L i n t"

start_time="$(start_timer)"

if ! type -P eslint &>/dev/null &&
    type -P npm; then
    npm install eslint
fi

if type -P eslint &>/dev/null; then
    type -P eslint
    eslint --version
    echo
    while read -r filename; do
        isExcluded "$filename" && continue
        echo "eslint $filename $*"
        eslint "$filename" "$@"
    done <<< "$files"
    hr; echo
fi

time_taken "$start_time"
section2 "EsLint checks passed"
echo
