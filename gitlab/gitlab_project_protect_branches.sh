#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-16 09:52:29 +0100 (Sun, 16 Aug 2020)
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
Enables branch protection for one or more branches in the given GitLab project (repo) to prevents deleting the branch or force pushing over it

If no branch is specified, the applies branches protections to any of the following branches if they're found:
$default_branches_to_protect

Project can be the full project name (eg. HariSekhon/DevOps-Bash-tools) or the project ID

Project username prefix can be omitted, will use \$GITLAB_USER if available, otherwise will query the GitLab API to determine the user owning the \$GITLAB_TOKEN

Automatically url encodes the project name and description for you since the GitLab API will return 404 and fail to find the project name if not url encoded

Uses the adajcent script gitlab_api.sh, see there for authentication details

\$CURL_OPTS can be set to provide extra arguments to curl
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<project> [<branch> <branch2> <branch3> ...]"

help_usage "$@"

min_args 1 "$@"

project="$1"
shift || :

if ! [[ "$project" =~ / ]]; then
    log "No username prefix in project '$project', will auto-add it"
    log "Attempting to infer username"
    if [ -n "${GITLAB_USER:-}" ]; then
        gitlab_user="$GITLAB_USER"
        log "Using username '$gitlab_user' from \$GITLAB_USER"
    else
        log "Querying GitLab API for currently authenticated username"
        gitlab_user="$("$srcdir/gitlab_api.sh" /user | jq -r .username)"
        log "GitLab API returned username '$gitlab_user'"
    fi
    project="$gitlab_user/$project"
fi

# url-encode project name otherwise GitLab API will fail to find project and return 404
project_name="$project"
project="$("$srcdir/../bin/urlencode.sh" <<< "$project")"

allow_force_push=false
code_owner_approval_required=true

protect_project_branch(){
    local branch="$1"
    timestamp "protecting GitLab project '$project_name' branch '$branch'"
    # gets  409 error if there is already branch protection, so remove and reapply it to ensure it is applied with these settings
    "$srcdir/gitlab_api.sh" "/projects/$project/protected_branches/$branch" -X DELETE &>/dev/null || :
    #if "$srcdir/gitlab_api.sh" "/projects/$project/protected_branches/$branch" &>/dev/null; then
        #timestamp "patching existing GitLab branch protection"
        # XXX: GitLab API ignores PATCH'ing allow_force_push, only works for code_owner_approval_required - the only way to enforce allow_force_push=false is to remove and recreate the branch protection
        #"$srcdir/gitlab_api.sh" "/projects/$project/protected_branches/$branch?allow_force_push=$allow_force_push&code_owner_approval_required=$code_owner_approval_required" -X PATCH >/dev/null
    #fi
    "$srcdir/gitlab_api.sh" "/projects/$project/protected_branches?name=$branch&allow_force_push=$allow_force_push&code_owner_approval_required=$code_owner_approval_required" -X POST >/dev/null
    timestamp "protection applied to branch '$branch'"
}

get_gitlab_project_branches(){
    local project="$1"
    local branches
    local page=1
    for ((page=1; page < 100; page++)); do
        branches="$("$srcdir/gitlab_api.sh" "/projects/$project/repository/branches?page=$page&per_page=100" | jq_debug_pipe_dump | jq -r '.[].name')"
        if [ -z "$branches" ]; then
            break
        fi
        echo "$branches"
    done
}

if [ $# -gt 0 ]; then
    for branch in "$@"; do
        protect_project_branch "$branch"
    done
else
    timestamp "no branches specified, getting branch list"
    branches="$(get_gitlab_project_branches "$project")"
    for branch in $default_branches_to_protect; do
        timestamp "checking for branch '$branch'"
        if grep -Fxq "$branch" <<< "$branches"; then
            timestamp "protecting branch '$branch'"
            protect_project_branch "$branch"
        fi
    done
fi
