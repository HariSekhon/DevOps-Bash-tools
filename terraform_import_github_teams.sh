#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-02-25 18:14:24 +0000 (Fri, 25 Feb 2022)
#
#  https://github.com/HariSekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "${BASH_SOURCE[0]}")"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Finds all github_team references in ./*.tf code and then queries the GitHub API for their IDs and if they exist imports them to Terraform state

The GitHub Organization must be specified as the first arg or found in \$GITHUB_ORGANIZATION environment variable

Requires the github_repository identifiers in *.tf code to match the GitHub team slug in the GitHub API


Requires Terraform and GitHub CLI to be installed and configured


See Also:

    github_teams_not_in_terraform.sh
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<organization> [<dir>]"

help_usage "$@"

org="${1:-${GITHUB_ORGANIZATION:-}}"
dir="${2:-.}"

if is_blank "$org"; then
    usage "Organization not specifieid"
fi

cd "$dir"

timestamp "getting terraform state"
terraform_state_list="$(terraform state list)"
echo >&2

timestamp "getting github repos from $PWD/*.tf code"
grep -E '^[[:space:]]*resource[[:space:]]+"github_team"' ./*.tf |
awk '{gsub("\"", "", $3); print $3}' |
while read -r team; do
    echo >&2
    if grep -Fq "github_team.$team" <<< "$terraform_state_list"; then
        echo "team '$team' already in terraform state, skipping..." >&2
        continue
    fi
    timestamp "querying team '$team'"
    id="$(gh api "/orgs/$org/teams/$team" | jq -r 'select(.id) | .id' || :)"
    if [ -z "$id" ]; then
        warn "team '$team' not found in GitHub API, skipping..."
        continue
    fi
    cmd="terraform import github_team.$team $id"
    timestamp "$cmd"
    $cmd
done
