#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: HariSekhon DevOps-Bash-tools
#
#  Author: Hari Sekhon
#  Date: 2021-09-14 15:44:55 +0100 (Tue, 14 Sep 2021)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://docs.github.com/en/rest/reference/repos#update-a-repository

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Disables Pull Request Rebase Merges on one or more given GitHub repos

For authentication and other details see:

    github_api.sh --help
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<owner> <repo> [<repo2> <repo3> ...]"

help_usage "$@"

min_args 2 "$@"

owner="$1"
shift || :

disable_pr_rebasing(){
    local repo="$1"
    timestamp "disabling PR rebasing on repo '$owner/$repo'"
    "$srcdir/github_api.sh" "/repos/$owner/$repo" -X PATCH -d '{"allow_rebase_merge": false}' |
    jq -e -r '[ "Rebase Merging: ", .allow_rebase_merge ] | @tsv'
}

for repo in "$@"; do
    disable_pr_rebasing "$repo"
done
