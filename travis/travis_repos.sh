#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
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
#. "$srcdir/lib/travis.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Lists all Travis CI repos using the Travis CI API

Since the API returns all GitHub repos, this code filters for those marked 'active'
which are the ones which show up in Travis CI and which run CI builds

Uses the adjacent travis_api.sh script
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<curl_options>]"

help_usage "$@"

next="/repos"

get_repos(){
    local url_path="$1"
    shift || :
    local output
    output="$("$srcdir/travis_api.sh" "$url_path" "$@")"
    jq -r '.repositories[] | select(.active == true) | .slug' <<< "$output"
    next="$(jq -r '.["@pagination"].next["@href"]' <<< "$output")"
}

# iterate over all next hrefs to get through all pages of repos
while [ -n "$next" ] &&
      [ "$next" != null ]; do
    get_repos "$next" "$@"
done
