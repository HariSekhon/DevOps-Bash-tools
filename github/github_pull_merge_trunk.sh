#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-06-19 19:12:25 +0200 (Wed, 19 Jun 2024)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
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

# shellcheck disable=SC2034,SC2154
usage_description="
Pulls the origin or forks upstream repo's trunk branch and merges it into the local branch

In a forked GitHub repo's checkout, determines the origin of the fork using GitHub CLI,
configures a git remote to the upstream, pulls the default branch and if on a branch other than the default
then merges the default branch to the local current branch

Simplifies and automates keeping your cloned or forked repo up to date with the original source repo to quickly resolve
merge conflicts locally and submit updated Pull Requests

Set environment variable GIT_REBASE=true if you want the pulls and merge to current branch to rebase instead of merge commit...
if you really love violating VCS history integrity! Personally, not a fan. You can also end up in rebase hell for a series of
commits that a default merge commit would have auto-resolved

Read:

    https://github.com/HariSekhon/Knowledge-Base/blob/main/git.md#the-evils-of-rebasing

Requires GitHub CLI to be installed and authenticated, as well as jq
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<owner/repo>]"

help_usage "$@"

max_args 1 "$@"

check_github_origin

if [ $# -gt 0 ]; then
    upstream_owner_repo="$1"
    shift
else
    if is_github_fork; then
        upstream_owner_repo="$(github_upstream_owner_repo || die "Not a forked repo?")"
    fi
fi

rebase="${GIT_REBASE:-false}"

if ! is_bool "$rebase"; then
    usage "GIT_REBASE environment variable must be set to 'true' or 'false'"
fi

if is_github_fork; then
    "$srcdir/github_remote_set_upstream.sh" "$upstream_owner_repo"
    echo
fi

default_branch="$(default_branch)"

# should be a straight fast-forward
timestamp "Pulling default branch '$default_branch' from origin"
echo
# --no-edit option isn't available to rebase
git pull origin "$default_branch" --rebase="$rebase" --no-edit
echo

if is_github_fork; then
    current_branch="$(git rev-parse --abbrev-ref HEAD)"

    if [ "$current_branch" = "$default_branch" ]; then
        timestamp "Pulling default branch '$default_branch' from upstream $upstream_owner_repo"
        git pull upstream "$default_branch" --no-edit
    else
        timestamp "Fetching default branch '$default_branch' from upstream $upstream_owner_repo"
        echo
        git fetch upstream "$default_branch:$default_branch"
        echo
        if [ "$rebase" = true ]; then
            timestamp "Rebasing current branch '$current_branch' from default branch '$default_branch'"
            git rebase "$default_branch"
        else
            timestamp "Merging default branch '$default_branch' into current branch '$current_branch'"
            git merge "$default_branch" --no-edit
        fi
    fi
fi
