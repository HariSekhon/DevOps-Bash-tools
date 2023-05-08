#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-02-28 17:14:19 +0000 (Mon, 28 Feb 2022)
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
Finds all GitHub organization teams that are not sync'd from na IdP like Azure AD (these should probbly be replaced/migrated/deleted if using IdP integration)

Org can be given as an arg or taken from environment variable \$GITHUB_ORGANIZATION

if \$QUIET is set then won't print progress to stderr, just the non-IdP sync'd teams tn stdout


Requires GitHub CLI to be installed and configured
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<org>"

help_usage "$@"

#min_args 1 "$@"

org="${1:-${GITHUB_ORGANIZATION:-}}"

if is_blank "$org"; then
    usage "Organization not defined"
fi

for((page=1;; page++)); do
    if [ "$page" -gt 100 ]; then
        die "Hit over 100 pages of teams, possible infinite loop, exiting..."
    fi
    if [ -z "${QUIET:-}" ]; then
        timestamp "getting list of teams page $page"
    fi
    data="$(gh api "/orgs/$org/teams?per_page=100&page=$page" | jq_debug_pipe_dump)"
    if jq_is_empty_list <<< "$data"; then
        break
    fi
    jq -r '.[].slug' <<< "$data" |
    while read -r team; do
        if [ -z "${QUIET:-}" ]; then
            timestamp "checking team '$team'"
        fi
        team_mappings="$(gh api "/orgs/$org/teams/$team/team-sync/group-mappings" | jq_debug_pipe_dump)"
        if jq -e 'select((.groups | length) == 0)' <<< "$team_mappings" >/dev/null; then
            if [ -z "${QUIET:-}" ]; then
                timestamp "WARNING: team '$team' is not sync'd' from an IdP!"
            fi
            echo "$team"
        fi
    done
    if jq -e 'length < 100' <<< "$data" >/dev/null; then
        break
    fi
done
