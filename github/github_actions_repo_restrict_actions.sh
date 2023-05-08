#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-01-26 18:44:00 +0000 (Wed, 26 Jan 2022)
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
. "$srcdir/lib/git.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Restricts the allowed GitHub Actions in the given repo to only those created by GitHub and verified partner companies (eg. AWS, Docker) using the GitHub API

If you have an Organization, I recommend you set this organization-wide instead, but for individual users this is handy to automate tightenting up your security

See Also:

    github_actions_repo_actions_allow.sh - applies this to all repos
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<user>/<repo>"

help_usage "$@"

#min_args 1 "$@"

repo="${1:-}"

if [ -z "$repo" ]; then
    repo="$(git_repo)"
fi

repo="$(perl -pne 's|^https://github.com/||i' <<< "$repo")"
repo="${repo##/}"

timestamp "Restricting GitHub Actions to selected actions on repo '$repo'"
"$srcdir/github_api.sh" "/repos/$repo/actions/permissions" -X PUT -d '{"enabled":true, "allowed_actions": "selected"}'

timestamp "Enabling GitHub and Verified Partners actions on repo '$repo'"
"$srcdir/github_api.sh" "/repos/$repo/actions/permissions/selected-actions" -X PUT -d '{"github_owned_allowed":true, "verified_allowed": true}'
