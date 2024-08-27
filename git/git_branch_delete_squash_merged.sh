#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-08-27 12:06:49 +0200 (Tue, 27 Aug 2024)
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
. "$srcdir/lib/git.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Carefully detects if a Git squash merged branch you want to delete has no changes vs the default trunk branch before deleting it

Doing a branch force delete without these checks risks losing all unpushed code changes on a branch

You need to run this on a clean trunk branch as it will check for any changed files (only untracked files are ignored)

If you don't think you can lose code by deleting the wrong branch just consider what happens when you repeatedly
work on area, branching each time but haven't been able to automatically prune old branches. You'll use similar names
and then may be confused about which is the old one to delete, run 'git branch -D' on the wrong one and congrats
you've just permanently lost all your unpushed work on that branch
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<branch>"
# TODO: consider allowing a second arg to explicitly specify the trunk branch
#       - shouldn't be needed in most sane cases though
#       - client who has dual trunk repo with prod deployments running off both develop and master
#         is a historical legacy mistake

help_usage "$@"

min_args 1 "$@"

branch="$1"

default_trunk_branch="$(default_branch)"

timestamp "Checking out default trunk branch '$default_trunk_branch'"
# this actually wipes out any previous the merge state test
# - if script were to crash out, simply re-running would be enough
git checkout "$default_trunk_branch"
echo

timestamp "Pulling latest changes"
git pull
echo

timestamp "Checking '$branch' branch contents vs '$default_trunk_branch' using a pseudo merge for any diffs"
# this git command only outputs to stderr so we must capture to stdout to test, and then re tee back to stderr
# to give good user visibility of the state message
output="$(git merge --no-ff --no-commit "$branch" 2>&1 | tee /dev/stderr)"
echo

# check for any changes in the checkout but ignore untracked files
if [ -z "$(git status --porcelain | sed '/^??/d')" ]; then
    timestamp "No content changes detected"
else
    timestamp "Changes detected from branch '$branch' or dirty checkout - branch may not be fully merged"
    timestamp "Aborting for safety"
    exit 1
fi

# "Automatic merge went well" is not enough - hence we need the content change check above
# and use this as a mere state confirmation here if we don't get an "Already up to date" message
if [[ "$output" =~ Already\ up\ to\ date|Automatic\ merge\ went\ well ]]; then
    timestamp "Branch is safe to delete"
    timestamp "Deleting branch '$branch'"
    git branch -D "$branch"
else
    timestamp "WARNING: branch '$branch' was not detected as safely merged into trunk '$default_trunk_branch'"
    echo
fi
git merge --abort
