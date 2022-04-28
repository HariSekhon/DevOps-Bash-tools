#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-03-31 17:37:12 +0100 (Thu, 31 Mar 2022)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://docs.github.com/en/rest/reference/collaborators

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/utils.sh
. "$srcdir/lib/utils.sh"

# shellcheck source=lib/git.sh
. "$srcdir/lib/github.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Adds a given user as a collaborate to the given GitHub repo with the specified permission (eg. for CI/CD machine accounts as outside invited collaborators) via GitHub API

Perm should usually be one of:

    pull
    push
    admin
    maintain
    triage

This is most useful for GitHub Enterprise Organization repos to add a CI/CD machine account programmatically, especially when combined with github_foreach_repo.sh.
Alternatively if you don't have SSO enforced you can add the machine account directly as a member of the Organization with default access to all repos

See Also:

    github_repo_collaborators.sh - show collaborators and their permissions to a given repo
    github_invitations.sh        - show or accept repos invites programmatically
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<owner>/<repo> <user> <permission>"

help_usage "$@"

min_args 2 "$@"

owner_repo=''

if [ $# -gt 3 ]; then
    owner_repo="$1"
    user="$2"
    perm="$3"
elif [ $# -eq 2 ]; then
    user="$1"
    perm="$2"
else
    usage "invalid number of args, must be 2 or 3"
fi

if [ -z "$owner_repo" ]; then
    owner_repo="$(get_github_repo)"
fi

timestamp "Adding collaborator '$user' to GitHub repo '$owner_repo'"
"$srcdir/github_api.sh" "/repos/$owner_repo/collaborators/$user" -X PUT -d '{"permission": "'"$perm"'" }'
