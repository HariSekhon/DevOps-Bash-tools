#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-11-30 19:06:40 +0000 (Mon, 30 Nov 2020)
#
#  https://github.com/HariSekhon/bash-tools
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

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Exports all TeamCity builds to local JSON configuration files for backup/restore / migration purposes, or even just to backport changes to Git for revision control tracking

Uses the adjacent teamcity_api.sh and jq (installed by 'make')

See teamcity_api.sh for required connection settings and authentication
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<build1> <build2> ...]"

help_usage "$@"

#min_args 1 "$@"

if [ $# -gt 0 ]; then
    for build_name in "$@"; do
        echo "$build_name"
    done
else
    "$srcdir/teamcity_api.sh" /buildTypes |
    jq -r '.buildType[].name'
fi |
grep -v '^[[:space:]]*$' |
while read -r build_name; do
    filename="$build_name.json"
    timestamp "downloading build '$build_name' to '$filename'"
    "$srcdir/teamcity_api.sh" "/buildTypes/$build_name" |
    # using jq just for formatting
    jq . > "$filename" || :  # some builds get 400 errors, ignore these
done
