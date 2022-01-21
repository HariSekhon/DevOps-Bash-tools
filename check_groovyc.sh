#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-01-06 18:34:01 +0000 (Thu, 06 Jan 2022)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  http://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Recurses a given directory tree or \$PWD, finding all Groovy files and validating them using 'groovyc'

Useful for doing basic linting on Groovy repos and Jenkinsfile shared libraries
"

help_usage "$@"

directory="${1:-.}"
shift ||:

filelist="$(find "$directory" -type f -iname '*.groovy' | sort)"
if [ -z "$filelist" ]; then
    return 0 &>/dev/null || :
    exit 0
fi

section "G r o o v y"

start_time="$(start_timer)"

if type -P groovyc &>/dev/null; then
    while read -r filename; do
        isExcluded "$filename" && continue
        echo "groovyc $filename $*"
        groovyc "$filename" "$@"
    done <<< "$filelist"
else
    echo "WARNING: groovyc not found in \$PATH, skipping Groovy checks"
    exit 0
fi

echo
time_taken "$start_time"
section2 "Groovy checks passed"
echo
