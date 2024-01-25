#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-16 11:23:29 +0100 (Sun, 16 Aug 2020)
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
Sync GitHub repo descriptions to GitLab and BitBucket repos of the same name

Queries the GitHub API for each repo's description, then pushes that description to repos of
the same name on GitLab via the GitLab API

If repos are given as arguments, then only sync's those repos, otherwise queries the GitHub API and iterates all repos

For more details see github_repo_description.sh, gitlab_project_set_description.sh for tuning options around authentication, user/organization for each site etc.
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<user/repo1> <user/repo2> ...]"

help_usage "$@"

export GIT_FOREACH_REPO_NO_HEADERS=1

if [ -n "$*" ]; then
    for repo; do
        "$srcdir/github_repo_description.sh" "$repo"
    done
else
    "$srcdir/github_foreach_repo.sh" "github_repo_description.sh '{owner}/{repo}'" 2>/dev/null
fi |
while read -r repo description; do
    "$srcdir/../gitlab/gitlab_project_set_description.sh" <<< "$repo $description"
    "$srcdir/../bitbucket/bitbucket_repo_set_description.sh" <<< "$repo $description"
done
