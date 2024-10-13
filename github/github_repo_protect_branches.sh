#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
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

# https://docs.github.com/en/rest/reference/repos#update-branch-protection

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/github.sh"

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

default_branches_to_protect="
    main
    master
    develop
    dev
    staging
    production
"

# shellcheck disable=SC2034,SC2154
usage_description="
Enables branch protection for one or more branches in the given GitHub repo (prevents deleting the branch or force pushing over it)

If no branch is specified, then applies branches protections to any of the following branches if they're found:
$default_branches_to_protect

XXX: Beware this could reset certain protection settings on the branch when run, such as enabling/disabling PR approvals due to the way the API bundles them together.
     This is the complete list of settings sent, which you'd need to modify near the top of this code to change:

$(jq . <<< "$settings")


For authentication and other details see:

    github_api.sh --help
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<owner> <repo> [<branch> <branch2> <branch3> ...]"

help_usage "$@"

#min_args 2 "$@"

owner="${1:-}"
repo="${2:-}"
shift || :
shift || :

#check_env_defined GH_TOKEN

if ! is_blank "$owner" &&
   !  is_blank "$repo"; then
    owner_repo="$owner/$repo"
else
    timestamp "No GitHub owner/repo specified - determining from current Git checkout"
    if ! is_in_git_repo; then
        usage "Did not specify owner and repo and not in a Git repo to try to infer it"
    fi
    owner_repo="$(get_github_repo || :)"
    if is_blank "$owner_repo"; then
        owner_repo="$(github_owner_repo)"
    fi
    timestamp "Inferred GitHub repo to be: $owner_repo"
fi

if ! is_github_owner_repo "$owner_repo"; then
    die "ERROR: invalid GitHub owner/repo provided, failed regex validation: $owner_repo"
fi

protect_repo_branch(){
    local branch="$1"
    timestamp "protecting GitHub repo '$owner_repo' branch '$branch'"
    "$srcdir/github_api.sh" "/repos/$owner_repo/branches/$branch/protection" -X PUT -d "$settings" >/dev/null
    timestamp "protection applied to branch '$branch'"
}

if [ $# -gt 0 ]; then
    for branch in "$@"; do
        protect_repo_branch "$branch"
    done
else
    timestamp "no branches specified, getting branch list"
    branches="$(get_github_repo_branches "$owner_repo")"
    for branch in $default_branches_to_protect; do
        timestamp "checking for branch '$branch'"
        if grep -Fxq "$branch" <<< "$branches"; then
            protect_repo_branch "$branch"
        fi
    done
fi
