#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-02-14 11:32:21 +0000 (Mon, 14 Feb 2022)
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
. "$srcdir/lib/github.sh"

BRANCHES_TO_PR_DEFAULT="
    master
    main
    develop
    dev
    staging
    production
"

# make this more explicit for user
BRANCHES_TO_AUTOMERGE_DEFAULT=""
#    master
#    main
#    develop
#    dev
#    staging
#"

# shellcheck disable=SC2034,SC2154
usage_description="
Updates the current or given repo fork via Pull Requests for full audit tracking

Creates Pull Requests for branches given as arguments or set in \$BRANCHES_TO_PR, or else by default the following branches if they are found:
$BRANCHES_TO_PR_DEFAULT

Auto-merges the PRs for branches set in \$BRANCHES_TO_AUTOMERGE or the following default branches:

${BRANCHES_TO_AUTOMERGE_DEFAULT:-<none>}

Requires GitHub CLI to be installed and configured

See also:

    github_repo_fork_recreate.sh - recreates a forked repo to clean out PRs and reset branches to be clean fast-forward merges
    gh repo sync - sync's a repo but lacks the auditing of Pull Requests
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<owner>/<repo> <branch1> <branch2> <branch3> ...]"

help_usage "$@"

#min_args 1 "$@"

owner_repo="${1:-}"
shift || :
branches="${*:-${BRANCHES_TO_PR:-$BRANCHES_TO_PR_DEFAULT}}"
branches_to_automerge="${BRANCHES_TO_AUTOMERGE:-$BRANCHES_TO_AUTOMERGE_DEFAULT}"

if is_blank "$owner_repo"; then
    if ! is_in_git_repo; then
        die "No repo given and not in a git repository checkout to infer it"
    fi
    owner_repo='{owner}/{repo}'
fi

repo_data="$(gh api "/repos/$owner_repo")"

is_fork="$(jq -r '.fork' <<< "$repo_data")"
owner="$(jq -r '.owner.login' <<< "$repo_data")"
repo="$(jq -r '.name' <<< "$repo_data")"

if [ "$is_fork" != true ]; then
    die "Repo '$owner/$repo' is not a forked repo, cannot raise a pull request from an original source repo"
fi

fork_source_owner="$(jq -r '.source.owner.login' <<< "$repo_data")"
fork_source_repo="$(jq -r '.source.full_name' <<< "$repo_data")"
fork_source_default_branch="$(jq -r '.source.default_branch' <<< "$repo_data")"

fork_repo_branches="$(get_github_repo_branches "$owner/$repo")"
source_repo_branches="$(get_github_repo_branches "$fork_source_repo")"

for branch in $branches; do
    # use function to iterate pages
    #if ! gh api "/repos/$owner/$repo/branches?per_page=100" -q '.[].name' | grep -Fxq "$branch"; then
    if ! grep -Fxq "$branch" <<< "$fork_repo_branches"; then
        timestamp "No local fork branch '$branch' found, skipping PR"
        echo >&2
        continue
    fi

    # use function to iterate pages
    #if gh api "/repos/$fork_source_repo/branches?per_page=100" -q '.[].name' | grep -Fxq "$branch"; then
    if grep -Fxq "$branch" <<< "$source_repo_branches"; then
        fork_source_branch="$branch"
    else
        fork_source_branch="$fork_source_default_branch"
    fi

    base="$branch"
    head="$fork_source_owner:$fork_source_branch"

    if tr '[:space:]' '\n' <<< "$branches_to_automerge" | sed '/^[[:space:]]*$/d' | grep -Fxq "$branch"; then
        "$srcdir/github_merge_branch.sh" "$owner_repo" "$head" "$base"
    else
        "$srcdir/github_pull_request_create.sh" "$owner_repo" "$head" "$base"
    fi
done
