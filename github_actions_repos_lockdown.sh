#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-01-26 19:22:46 +0000 (Wed, 26 Jan 2022)
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
Secures the allowed GitHub Actions across all repos for the user

Uses:
        github_actions_repo_restrict_actions.sh
        github_actions_repo_actions_allow.sh

If you have an Organization, I recommend you set this organization-wide instead, but for individual users this is handy to automate tightenting up your security

TODO: restrict token permissions to default to minimal content read only, but the GitHub API does not support managing this at time of writing
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

#min_args 1 "$@"

user="$(get_github_user)"

get_github_repos "$user" |
while read -r repo; do
    github_actions_repo_restrict_actions.sh "$user/$repo"
    github_actions_repo_actions_allow.sh "$user/$repo"
    echo
done
