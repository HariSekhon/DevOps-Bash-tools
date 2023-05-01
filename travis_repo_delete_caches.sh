#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: DevOps-Bash-tools
#  args: HariSekhon/DevOps-Bash-tools
#
#  Author: Hari Sekhon
#  Date: 2020-10-01 00:19:22 +0100 (Thu, 01 Oct 2020)
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
Deletes all caches for the given Travis CI repo

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

repo_encoded="$(travis_prefix_encode_repo "$repo")"

timestamp "Deleting all caches for repo '$repo'"
"$srcdir/travis_api.sh" "/repo/$repo_encoded/caches" -X DELETE "$@"
