#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-01-26 19:58:49 +0000 (Wed, 26 Jan 2022)
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

# shellcheck disable=SC2034,SC2154
usage_description="
Finds all GitHub Actions in use from the .github/workflows directory across all workflows in all original source repos for the user or organization

This is useful to combine with github_actions_repo_actions_allow.sh and github_actions_repos_lockdown.sh
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

#min_args 1 "$@"

user_or_org="${1:-${GITHUB_ORGANIZATION:-${GITHUB_USER:-$(get_github_user)}}}"

get_github_repos "$user_or_org" "${GITHUB_ORGANIZATION:-}" |
while read -r repo; do
    "$srcdir/github_actions_in_use_repo.sh" "$user_or_org/$repo"
    echo >&2
done # |
#sort -u
