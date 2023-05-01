#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: DevOps-Bash-tools
#  args: HariSekhon/DevOps-Bash-tools
#
#  Author: Hari Sekhon
#  Date: 2020-09-30 20:47:00 +0100 (Wed, 30 Sep 2020)
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
. "$srcdir/lib/travis.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Lists all crons for a given Travis CI repo using the Travis CI API

If no repo is given, then tries to determine the repo name from the local git remote url


Output Format:

<id>    <branch>    <interval>    <created_at>    <last_run>    <next_run>


If the repo doesn't have a user / organization prefix, then queries
the Travis CI API for the currently authenticated username first

Uses the adjacent travis_api.sh script
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<user>/]<repo> [<curl_options>]"

help_usage "$@"

#min_args 1 "$@"

repo="${1:-}"
shift || :

repo="$(travis_prefix_encode_repo "$repo")"

next="/repo/$repo/crons"

get_crons(){
    local url_path="$1"
    shift || :
    local output
    output="$("$srcdir/travis_api.sh" "$url_path" "$@")"
    jq -r '.crons[] | [.id, .branch.name, .interval, .created_at, .last_run, .next_run] | @tsv' <<< "$output"
    next="$(jq -r '.["@pagination"].next["@href"]' <<< "$output")"
}

# iterate over all next hrefs to get through all pages of crons
while [ -n "$next" ] &&
      [ "$next" != null ]; do
    get_crons "$next" "$@"
done
