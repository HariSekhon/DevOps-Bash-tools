#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: echo user={user} name={name} repo={repo}
#
#  Author: Hari Sekhon
#  Date: 2020-08-30 10:08:07 +0100 (Sun, 30 Aug 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir_github_lib="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir_github_lib/utils.sh"

# shellcheck disable=SC1090
. "$srcdir_github_lib/git.sh"

get_github_repo(){
    git remote -v 2>/dev/null |
    grep github.com |
    awk '{print $2}' |
    head -n1 |
    sed '
        s,.*://,,;
        s/.*@//;
        s/[^:/]*[:/]//;
        s/\.git$//;
    '
}

is_github_owner_repo(){
    local repo="$1"
    # .github repo is valid
    [[ "$repo" =~ ^[[:alnum:]-]+/[[:alnum:]._-]+$ ]]
}

get_github_user(){
    if [ -n "${GITHUB_USER:-}" ]; then
        echo "$GITHUB_USER"
    else
        # get currently authenticated user
        "$srcdir_github_lib/../github_api.sh" /user | jq -r .login
    fi
}

github_result_has_more_pages(){
    local output="$1"
    if [ -z "$(jq '.[]' <<< "$output")" ]; then
        return 1
    elif jq -r '.message' <<< "$output" >&2 2>/dev/null; then
        exit 1
    fi
    return 0
}

get_github_repos(){
    local owner="${1:-}"
    if [ -z "$owner" ]; then
        owner="$(get_github_user)"
    fi
    local is_org="${2:-}"
    local filter="${3:-.}"
    local prefix
    if [ -n "$is_org" ]; then
        prefix="orgs"
    else
        prefix="users"
    fi
    local page=1
    while true; do
        if ! output="$("$srcdir_github_lib/../github_api.sh" "/$prefix/$owner/repos?page=$page&per_page=100")"; then
            echo "ERROR" >&2
            exit 1
        fi
        if [ -z "$(jq '.[]' <<< "$output")" ]; then
            break
        elif jq -r '.message' <<< "$output" >&2 2>/dev/null; then
            exit 1
        fi
        jq_debug_pipe_dump <<< "$output" |
        jq -r ".[] | select(.fork | not) | $filter | .name"
        ((page+=1))
    done
}

get_github_repo_branches(){
    local repo="$1"
    local page=1
    while true; do
        if ! output="$("$srcdir_github_lib/../github_api.sh" "/repos/$repo/branches?page=$page&per_page=100")"; then
            echo "ERROR" >&2
            exit 1
        fi
        if [ -z "$(jq '.[]' <<< "$output")" ]; then
            break
        elif jq -r '.message' <<< "$output" >&2 2>/dev/null; then
            exit 1
        fi
        jq_debug_pipe_dump <<< "$output" |
        jq -r ".[].name"
        ((page+=1))
    done
}
