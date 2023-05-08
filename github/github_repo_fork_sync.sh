#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-06-17 00:12:59 +0100 (Fri, 17 Jun 2022)
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

# shellcheck disable=SC2034,SC2154
usage_description="
Sync's the current fork repo or from the original source repo sync's all repos matching the given ERE regex

First calls a repo sync of the trunk branch, then and calls github_repo_fork_update.sh to raise Pull Requests from trunk to the major branches

If not running in a fork checkout but the \$GITHUB_FORK_REGEX environment is set to any value, then the first argument regex can be omitted

Requires GitHub CLI to be installed and configured
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<fork_owner_repo_regex>]"

help_usage "$@"

#min_args 1 "$@"

regex="${1:-${GITHUB_FORK_REGEX:-}}"

timestamp "Determining if running from within a forked repo checkout"
is_fork="$(gh api "/repos/{owner}/{repo}" -q '.fork')"

if [ "$is_fork" = true ]; then
    timestamp "Confirmed running from within a forked repo checkout"
    fork_repos='{owner}/{repo}'
else
    timestamp "Not running from a forked repo checkout"
    if [ -z "$regex" ]; then
        usage "not running in a fork repo and no regex given to select a fork to sync"
    fi

    timestamp "Getting all forked repos matching regex '$regex'"
    set +o pipefail
    fork_repos="$(gh api '/repos/{owner}/{repo}/forks' -q '.[].full_name' | grep -Ei "$regex")"
    set -o pipefail

    if [ -z "$fork_repos" ]; then
        die "Failed to find an forked repos matching regex '$regex'"
    fi
fi

for owner_repo in $fork_repos; do
    echo
    timestamp "Sync'ing fork $owner_repo"
    gh repo sync "$owner_repo"
    echo
    timestamp "Raising Pull Requests to major branches for fork $owner_repo"
    "$srcdir/github_repo_fork_update.sh" "$owner_repo"
done

timestamp "Fork Sync done"

#gh workflow -R "$fork_repo" run fork-update-pr.yaml -f debug=false
#
#sleep 5
#
#id="$(gh run list --workflow=fork-update-pr.yaml -R "$fork_repo" -L 1 --json databaseId --jq '.[].databaseId')"
#
#gh run watch "$id" -R "$fork_repo"
