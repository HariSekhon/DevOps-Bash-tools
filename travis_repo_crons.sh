#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: HariSekhon/DevOps-Bash-tools
#
#  Author: Hari Sekhon
#  Date: 2020-09-30 20:47:00 +0100 (Wed, 30 Sep 2020)
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

# shellcheck disable=SC2034,SC2154
usage_description="
Lists all crons for a given Travis CI repo using the Travis CI API

Output Format:

<id>    <branch>    <interval>    <created_at>    <last_run>    <next_run>

Uses the adjacent travis_api.sh script
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

min_args 1 "$@"

repo="$1"
repo="${repo//\//%2F}"

next="/repo/$repo/crons"

get_crons(){
    local url_path="$1"
    local output
    if [ -n "${DEBUG:-}" ]; then
        timestamp "getting $url_path"
    fi
    output="$("$srcdir/travis_api.sh" "$url_path")"
    if [ -n "${DEBUG:-}" ]; then
        jq . <<< "$output"
    fi
    jq -r '.crons[] | [.id, .branch.name, .interval, .created_at, .last_run, .next_run] | @tsv' <<< "$output"
    next="$(jq -r '.["@pagination"].next["@href"]' <<< "$output")"
}

# iterate over all next hrefs to get through all pages of crons
while [ -n "$next" ] &&
      [ "$next" != null ]; do
    get_crons "$next"
done
