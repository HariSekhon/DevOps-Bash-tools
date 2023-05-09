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
Parses Terraform Plan output, find all github_team_repository references that would be added, queries the GitHub API to determine if they exist, and if so imports them

Terraform Plan is used because the team_id is also needed for import but is often a terraform reference which only resolves at runtime


The GitHub Organization must be specified as the first arg or found in \$GITHUB_ORGANIZATION environment variable

If \$TERRAFORM_PRINT_ONLY is set to any value, prints the commands to stdout to collect so you can check, collect into a text file or pipe to a shell or further manipulate, ignore errors etc.

Requires Terraform and GitHub CLI to be installed and configured. Tested on Terraform 1.1.6
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<organization> [<dir>]"

help_usage "$@"

org="${1:-${GITHUB_ORGANIZATION:-}}"
dir="${2:-.}"

if is_blank "$org"; then
    usage "Organization not specified"
fi

cd "$dir"

timestamp "getting GitHub org id for org '$org'"
org_id="$(gh api "/orgs/$org" | jq -r .id)"
timestamp "org id determined to be '$org_id'"
echo >&2

timestamp "getting terraform plan"
terraform_plan="$(terraform plan -no-color)"
echo >&2

timestamp "parsing github_team_repository references"
grep -E -e '^[[:space:]]+\+[[:space:]]+resource[[:space:]]+"github_team_repository"' \
        -e '^[[:space:]]+\+[[:space:]]+repository[[:space:]]+=' \
        -e '^[[:space:]]+\+[[:space:]]+team_id[[:space:]]+=' \
        <<< "$terraform_plan" |
sed 's/.*=//; s/.*resource "github_team_repository"//' |
awk '{gsub("\"", "", $1); print $1}' |
# collapses every 3 lines together
xargs -d '\n' -n 3 echo |
while read -r team_repo repo team_id; do
    echo >&2
    timestamp "querying repo '$repo'"
    if ! gh api "/repos/$org/$repo" | jq -e '.id' >/dev/null; then
        warn "repo '$repo' not found in GitHub API, skipping..."
        continue
    fi
    timestamp "querying team id '$team_id'"
    if ! gh api "/organizations/$org_id/team/$team_id" | jq -e '.id' >/dev/null; then
        warn "team id '$team_id' not found in GitHub API, skipping..."
        continue
    fi
    cmd=(terraform import "github_team_repository.$team_repo" "$team_id:$repo")
    timestamp "${cmd[*]}"
    if [ -z "${TERRAFORM_PRINT_ONLY:-}" ]; then
        "${cmd[@]}"
    fi
done
