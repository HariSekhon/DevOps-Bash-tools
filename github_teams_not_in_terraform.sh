#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-02-25 16:00:24 +0000 (Fri, 25 Feb 2022)
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
Finds all GitHub organization teams which are not found in ./*.tf code

Useful to catch teams sync'd from an IdP like AAD that require referencing in team repo assignments

Requires the GitHub Organization to be specified as an arg or found in \$GITHUB_ORGANIZATION environment variable

This relies on the GitHub team slug matching the terraform team identifier


Requires GitHub CLI to be installed and configured
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<organization>"

help_usage "$@"

#min_args 1 "$@"

org="${1:-${GITHUB_ORGANIZATION:-}}"

if is_blank "$org"; then
    usage "Organization not specifieid"
fi

teams="$(
    for((page=1; ; page++)); do
        data="$(gh api "/orgs/$org/teams?per_page=100&page=$page")"
        if [ "$(jq -r 'length' <<< "$data")" -lt 1 ]; then
            break
        fi
        jq -r '.[].slug' <<< "$data"
        ((page+=1))
        if [ "$page" -gt 1000 ]; then
            die "Hit 1000 pages of 100 teams per page, there is probably a bug"
        fi
    done |
    sort -f
)"

for team in $teams; do
    grep -Eq '^[[:space:]]*resource[[:space:]]+"github_team"[[:space:]]+"'"$team"'"' ./*.tf ||
    echo "$team"
done
