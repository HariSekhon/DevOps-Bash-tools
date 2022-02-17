#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-02-17 11:32:45 +0000 (Thu, 17 Feb 2022)
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
. "$srcdir/lib/github.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Creates a GitHub Pull Request, first checking if there is already a PR between the branches,
and also checks if there are actual commit differences between the branches to avoid common errors from blindly raising PRs

Helpful to automate creating Pull Requests across environments

Also works across repo forks if the head branch contains an '<owner>:' prefix

Useful Git terminology reminder:

The BASE branch is the branch you want to merge INTO, eg. 'production'
The HEAD branch is the branch you want to merge FROM, eg. 'staging' for audited code promotion

Used by adjacent scripts:

    github_merge_branch.sh
    github_repo_fork_update.sh
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<owner>/<repo>] <from_head_branch> <to_base_branch>"

help_usage "$@"

min_args 2 "$@"
max_args 3 "$@"

owner_repo=""
if [ $# -eq 3 ]; then
    owner_repo="$1"
    shift || :
fi

head="$1"
base="$2"

if is_blank "$owner_repo"; then
    if ! is_in_git_repo; then
        die "No repo given and not in a git repository checkout to infer it"
    fi
    owner_repo='{owner}/{repo}'
fi

repo_data="$(gh api "/repos/$owner_repo")"

owner="$(jq -r '.owner.login' <<< "$repo_data")"
repo="$(jq -r '.name' <<< "$repo_data")"

if [[ "$head" =~ : ]]; then
    head_owner="${head%%:*}"
    head_name="${head##*:}"
else
    head_owner="$owner"
    head_name="$head"
fi

total_commits="$(gh api "/repos/$owner/$repo/compare/$base...$head" -q '.total_commits')"
if [ "$total_commits" -gt 0 ]; then
    # check for existing PR between these branches before creating another
    existing_pr="$(gh pr list -R "$owner/$repo" \
        --json baseRefName,changedFiles,commits,headRefName,headRepository,headRepositoryOwner,isCrossRepository,number,state,title,url \
        -q ".[] |
            select(.baseRefName == \"$base\") |
            select(.headRefName == \"$head_name\") |
            select(.headRepositoryOwner.login == \"$head_owner\")
    ")"
    existing_pr_url="$(jq -r '.url' <<< "$existing_pr")"
    if [ -n "$existing_pr" ]; then
        timestamp "Branch '$base' already has an existing pull request from '$head', skipping PR: $existing_pr_url"
        echo >&2
        exit 0
    fi
    timestamp "Creating Pull Request from head '$head' into base branch '$base'"
    # --no-maintainer-edit is important, otherwise member ci account gets error (and yes there is a double 'Fork collab' error in GitHub CLI's error message):
    # pull request create failed: GraphQL: Fork collab Fork collab can't be granted by someone without permission (createPullRequest)
    gh pr create -R "$owner/$repo" --base "$base" --head "$head" --title "Merge $head branch to $base branch" --body "Created automatically by script \`${0##*/}\` in the [DevOps Bash tools](https://github.com/HariSekhon/DevOps-Bash-tools) repo." --no-maintainer-edit
    echo >&2
else
    timestamp "Branch '$base' is already up to date with upstream, skipping PR"
    echo >&2
fi
