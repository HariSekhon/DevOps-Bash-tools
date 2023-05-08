#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-02-24 14:07:02 +0000 (Thu, 24 Feb 2022)
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
Checks for any errors in the current or given GitHub repo's committed CODEOWNERS file

By default checks the CODEOWNERS for the default branch, unless a second argument is given specifying another branch name

Requires GitHub CLI and jq to be installed
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<owner>/<repo> <ref>]"

help_usage "$@"

#min_args 1 "$@"

owner_repo="${1:-}"
ref="${2:-}"

section 'GitHub CodeOwners check'

start_time="$(start_timer)"

if is_blank "$owner_repo"; then
    timestamp "repo not specified, determining self"
    owner_repo="$(gh api '/repos/{owner}/{repo}' | jq -r .full_name)"
    timestamp "determined repo to be '$owner_repo'"
    echo >&2
fi

if is_blank "$ref"; then
    timestamp "ref not specified, attempting to determine from current branch"
    #ref="$(mybranch)"
    #timestamp "determined current branch to be '$ref'"
    ref="$(gh api "/repos/$owner_repo" | jq -r .default_branch)"
    timestamp "determined default branch to be '$ref'"
    echo >&2
fi

url="/repos/$owner_repo/codeowners/errors"

if ! is_blank "$ref"; then
    url+="?ref=$ref"
fi

timestamp "Checking for CODEOWNERS errors in ref '$ref' via the GitHub API"
data="$(gh api "$url")"

error_count="$(jq -r '.error | length' <<< "$data")"

if [ "$error_count" -gt 0 ]; then
    echo "Error: CODEOWNERS file errors detected for repo '$owner_repo'"
    echo
    jq <<< "$data"

fi

time_taken "$start_time"
section2 "OK: no CODEOWNERS errors found for repo '$owner_repo'"
echo
