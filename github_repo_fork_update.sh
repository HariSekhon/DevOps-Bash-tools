#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-02-14 11:32:21 +0000 (Mon, 14 Feb 2022)
#
#  https://github.com/HariSekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "${BASH_SOURCE[0]}")"

# shellcheck disable=SC1090
. "$srcdir/lib/git.sh"

BRANCHES_TO_PR_DEFAULT="
master
main
develop
dev
staging
production
"

BRANCHES_TO_AUTOMERGE_DEFAULT="
master
main
develop
dev
staging
"

# shellcheck disable=SC2034,SC2154
usage_description="
Creates Pull Requests to update the given or current repo if it is a fork from its original source repo

Creates Pull Requests for branches given as arguments or set in \$BRANCHES_TO_PR, or else by default the following branches if they are found:
$BRANCHES_TO_PR_DEFAULT

Auto-merges the PRs for branches set in \$BRANCHES_TO_AUTOMERGE or the following default branches:
$BRANCHES_TO_AUTOMERGE_DEFAULT
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
    die "Repo '$owner_repo' is not a forked repo, cannot raise a pull request from an original source repo"
fi

fork_source_owner="$(jq -r '.source.owner.login' <<< "$repo_data")"
fork_source_repo="$(jq -r '.source.full_name' <<< "$repo_data")"
fork_source_default_branch="$(jq -r '.source.default_branch' <<< "$repo_data")"

for branch in $branches; do
    if ! gh api "/repos/$owner/$repo/branches" -q '.[].name' | grep -Fxq "$branch"; then
        timestamp "No local fork branch '$branch' found, skipping PR"
        echo >&2
        continue
    fi
    if gh api "/repos/$fork_source_repo/branches" -q '.[].name' | grep -Fxq "$branch"; then
        fork_source_branch="$branch"
    else
        fork_source_branch="$fork_source_default_branch"
    fi
    base="$branch"
    head="$fork_source_owner":"$fork_source_branch"
    total_commits="$(gh api "/repos/$owner/$repo/compare/$base...$head" -q '.total_commits')"
    if [ "$total_commits" -gt 0 ]; then
        existing_pr="$(gh pr list -R "$owner/$repo" \
            --json baseRefName,changedFiles,commits,headRefName,headRepository,headRepositoryOwner,isCrossRepository,number,state,title,url \
            -q ".[] |
                select(.baseRefName == \"$base\") |
                select(.headRefName == \"$fork_source_branch\") |
                select(.headRepositoryOwner.login == \"$fork_source_owner\")
        ")"
        existing_pr_url="$(jq -r '.url' <<< "$existing_pr")"
        if [ -n "$existing_pr" ]; then
            timestamp "Branch '$base' already has an existing pull request ($existing_pr_url), skipping PR"
            echo >&2
            continue
        fi
        timestamp "Creating Pull Request from upstream source repo for branch '$base'"
        # --no-maintainer-edit is important, otherwise member ci account gets error (and yes there is a double 'Fork collab' error in GitHub CLI's error message):
        # pull request create failed: GraphQL: Fork collab Fork collab can't be granted by someone without permission (createPullRequest)
        output="$(gh pr create -R "$owner/$repo" --base "$base" --head "$head" --title "Merge upstream $fork_source_branch branch to $base" --body "Created automatically by script: ${0##*/}" --no-maintainer-edit)"
        echo >&2
        pr_url="$(grep '/pull/' <<< "$output")"
        if grep -Fxq "$branch" <<< "$branches_to_automerge"; then
            timestamp "Merging Pull Request #${pr_url##*/} from upstream source repo for branch '$base'"
            gh pr merge --merge "$pr_url"
            echo >&2
        fi
    else
        timestamp "Branch '$base' is already up to date with upstream, skipping PR"
        echo >&2
    fi
done
