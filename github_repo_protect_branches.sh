#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-09-14 15:44:55 +0100 (Tue, 14 Sep 2021)
#
#  https://github.com/HariSekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://docs.github.com/en/rest/reference/repos#update-branch-protection

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "${BASH_SOURCE[0]}")"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

settings='
{
    "allow_force_pushes": false,
    "allow_deletions": false,
    "enforce_admins": true,
    "required_status_checks": null,
    "required_pull_request_reviews": null,
    "restrictions": null
}
'

# shellcheck disable=SC2034,SC2154
usage_description="
Enables branch protection for one or more branches in the given GitHub repo (prevents deleting the branch or force pushing over it)

If not branch is specified, applies to the 'master', 'main', 'develop' branches by default if they are found in the repo

XXX: Beware this could reset certain protection settings on the branch when run, such as enabling/disabling PR approvals due to the way the API bundles them together.
     This is the complete list of settings sent, which you'd need to modify near the top of this code to change:

$(jq . <<< "$settings")


For authentication and other details see:

    github_api.sh --help
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<organization> <repo> [<branch> <branch2> <branch3> ...]"

help_usage "$@"

min_args 2 "$@"

org="$1"
repo="$2"
shift || :
shift || :

protect_repo_branch(){
    local branch="$1"
    timestamp "protecting GitHub organization '$org' repo '$repo' branch '$branch'"
    "$srcdir/github_api.sh" "/repos/$org/$repo/branches/$branch/protection" -X PUT -d "$settings" >/dev/null
    timestamp "protection applied to branch '$branch'"
}

if [ $# -gt 0 ]; then
    for branch in "$@"; do
        protect_repo_branch "$branch"
    done
else
    timestamp "no branches specified, getting branch list"
    branches="$("$srcdir/github_api.sh" "/repos/$org/$repo/branches" | jq -r '.[].name')"
    for branch in main master develop; do
        timestamp "checking for branch '$branch'"
        if grep -Fxq "$branch" <<< "$branches"; then
            protect_repo_branch "$branch"
        fi
    done
fi
