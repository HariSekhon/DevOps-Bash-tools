#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: HariSekhon/DevOps-Bash-tools
#
#  Author: Hari Sekhon
#  Date: 2020-10-16 09:51:44 +0100 (Fri, 16 Oct 2020)
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
Triggers a build for the given Travis CI repo

If no repo is given, then tries to determine the repo name from the local git remote url

If the repo doesn't have a user / organization prefix, then queries
the Travis CI API for the currently authenticated username first

Uses the adjacent travis_*.sh scripts
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<user>/]<repo> [<curl_options>]"

help_usage "$@"

#min_args 1 "$@"

repo="${1:-}"
shift || :

if [ -z "$repo" ]; then
    repo="$(git_repo)"
fi

timestamp "Triggering Travis CI build for repo '$repo'"

repo="$(travis_prefix_encode_repo "$repo")"

"$srcdir/travis_api.sh" "/repo/$repo/requests" -X POST "$@"
