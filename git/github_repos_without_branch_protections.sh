#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-09-14 15:44:55 +0100 (Tue, 14 Sep 2021)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://docs.github.com/en/rest/reference/repos#update-branch-protection

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/github.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Finds repos for the given user or organization that have no branch protections enabled

\$GITHUB_ORGANIZATION must be set if querying an organization

For authentication and other details see:

    github_api.sh --help
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<organization_or_owner>"

help_usage "$@"

#min_args 1 "$@"

user_or_org="${1:-${GITHUB_ORGANIZATION:-${GITHUB_USER:-$(get_github_user)}}}"

get_github_repos "$user_or_org" "${GITHUB_ORGANIZATION:-}" |
while read -r name; do
    repo="$user_or_org/$name"
    page=1
    protected_branches=""
    while true; do
        if ! output="$("$srcdir/github_api.sh" "/repos/$repo/branches?page=$page&per_page=100")"; then
            echo "ERROR" >&2
            exit 1
        fi
        if [ -z "$(jq '.[]' <<< "$output")" ]; then
            break
        elif jq -r '.message' <<< "$output" >&2 2>/dev/null; then
            exit 1
        fi
        protected_branches="$protected_branches
                            $(jq_debug_pipe_dump <<< "$output" |
                              jq -r '.[] | select(.protected == true)')"
        ((page+=1))
    done
    if is_blank "$protected_branches"; then
        echo "$name"
    fi
done
