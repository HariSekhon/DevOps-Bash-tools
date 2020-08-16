#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-16 11:23:29 +0100 (Sun, 16 Aug 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Sync GitHub repo descriptions to GitLab repos

Queries the GitHub API for each repo's description, then pushes that description to repos of
the same name on GitLab via the GitLab API

For more details see github_repo_description.sh, gitlab_set_project_description.sh for tuning options around authentication, user/organization for each site etc.
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

GIT_FOREACH_REPO_NO_HEADERS=1 \
"$srcdir/git_foreach_repo.sh" "github_repo_description.sh '{repo}'" |
"$srcdir/gitlab_set_project_description.sh"
