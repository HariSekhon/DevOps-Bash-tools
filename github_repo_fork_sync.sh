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

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Sync's the current fork repo or from the original source repo sync's the first fork repo that matches the given ERE regex using a repo sync and calling the fork-update-pr workflow to raise Pull Requests from trunk to the major branches

Requires GitHub CLI to be installed and configured
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<fork_owner_repo_regex>]"

help_usage "$@"

#min_args 1 "$@"

regex="${1:-${GITHUB_FORK_REPO:-}}"

is_fork="$(gh api "/repos/{owner}/{repo}" -q '.fork')"

if [ "$is_fork" = true ]; then
    fork_repo='{owner}/{repo}'
else
    if [ -z "$regex" ]; then
        usage "not running in a fork repo and no regex given to select a fork to sync"
    fi

    set +o pipefail
    fork_repo="$(gh api '/repos/{owner}/{repo}/forks' -q '.[].full_name' | grep -Eim1 "$regex")"
    set -o pipefail

    if [ -z "$fork_repo" ]; then
        die "Failed to find a fork repo matching regex '$regex'"
    fi
fi

gh repo sync "$fork_repo"

"$srcdir/github_repo_fork_update.sh" "$fork_repo"

#gh workflow -R "$fork_repo" run fork-update-pr.yaml -f debug=false
#
#sleep 5
#
#id="$(gh run list --workflow=fork-update-pr.yaml -R "$fork_repo" -L 1 --json databaseId --jq '.[].databaseId')"
#
#gh run watch "$id" -R "$fork_repo"
