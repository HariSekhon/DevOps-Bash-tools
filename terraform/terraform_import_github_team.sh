#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-02-25 18:14:24 +0000 (Fri, 25 Feb 2022)
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
Terraform imports a given GitHub team into a given Terraform resource, by first querying the GitHub API for the team ID needed to import into Terraform

The GitHub Organization must be specified as the second arg or found in \$GITHUB_ORGANIZATION environment variable

If \$TERRAFORM_PRINT_ONLY is set to any value, prints the commands to stdout to collect so you can check, collect into a text file or pipe to a shell or further manipulate, ignore errors etc.

Requires Terraform and GitHub CLI to be installed and configured


See Also:

    github_teams_not_in_terraform.sh
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<terraform_state_resource> <github_team> [<github_organization>]"

help_usage "$@"

min_args 2 "$@"
max_args 3 "$@"

resource="$1"
team="$2"
org="${3:-${GITHUB_ORGANIZATION:-}}"

if is_blank "$org"; then
    usage "Organization not specified"
fi

timestamp "querying GitHub team '$team' for ID"
id="$(gh api "/orgs/$org/teams/$team" | jq -r 'select(.id) | .id' || :)"
if [ -z "$id" ]; then
    die "ERROR: team '$team' not found in GitHub API"
fi
cmd=(terraform import "'$resource'" "$id")
timestamp "${cmd[*]}"
if [ -z "${TERRAFORM_PRINT_ONLY:-}" ]; then
    "${cmd[@]}"
fi
