#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2026-07-10 23:07:28 +0200 (Fri, 10 Jul 2026)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn
#  and optionally send me feedback
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/github.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Finds all forks of a repo that contain a given commit hash to find private information for removal requests

If a repo is not specified, operates on the current repo

Requires GitHub CLI to be installed and configured for authentication
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<owner/repo>] <commit_hashref>"

help_usage "$@"

min_args 1 "$@"
max_args 2 "$@"

if [ $# -eq 2 ]; then
    owner_repo="$1"
    commit_hashref="$2"
elif [ $# -eq 1 ]; then
    owner_repo="$(github_owner_repo)"
    commit_hashref="$1"
else
    usage
fi

if ! is_github_owner_repo "$owner_repo"; then
    usage "Invalid GitHub owner/repo given: $owner_repo"
fi

if ! is_git_hashref "$commit_hashref"; then
    usage "Invalid Git commit hashref given: $commit_hashref"
fi

log "Fetching forks for repo: $owner_repo"
gh api "repos/$owner_repo/forks?per_page=100" --paginate --jq '.[].full_name' |
while read -r fork; do
    log "Fetching branches for fork: $fork"
    # ignore 404 error with error exit code - fork returns no branches, repo might have been deleted
    branches="$(gh api "repos/$fork/branches" --paginate --jq '.[].name' || :)"
    if [[ "$branches" =~ Not.Found|"status":"404" ]]; then
        continue
    fi
    for branch in $branches; do
        log "Checking if commit hash is an ancestor of '$fork' branch '$branch'"
        # ignore 404 errors which means the commit is not found in the repo
        commit_ancestry_status="$(
            gh api "repos/$fork/compare/${commit_hashref}...$branch" \
                --jq .status 2>/dev/null || :
        )"
        if [[ "$commit_ancestry_status" =~ ^(ahead|identical)$ ]]; then
            echo "https://github.com/$fork"
            break
        fi
    done
done
