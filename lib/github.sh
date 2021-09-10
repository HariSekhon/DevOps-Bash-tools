#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: echo user={user} name={name} repo={repo}
#
#  Author: Hari Sekhon
#  Date: 2020-08-30 10:08:07 +0100 (Sun, 30 Aug 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir_github_lib="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir_github_lib/../lib/utils.sh"

get_github_user(){
    if [ -n "${GITHUB_USER:-}" ]; then
        echo "$GITHUB_USER"
    else
        # get currently authenticated user
        "$srcdir_github_lib/../github_api.sh" /user | jq -r .username
    fi
}

get_github_repos(){
    local user="${1:-}"
    if [ -z "$user" ]; then
        user="$(get_github_user)"
    fi
    local is_org="${2:-}"
    local prefix
    if [ -n "$is_org" ]; then
        prefix="orgs"
    else
        prefix="users"
    fi
    local page=1
    while true; do
        if ! output="$("$srcdir_github_lib/../github_api.sh" "/$prefix/$user/repos?page=$page&per_page=100")"; then
            echo "ERROR" >&2
            exit 1
        fi
        if [ -z "$(jq '.[]' <<< "$output")" ]; then
            break
        elif jq -r '.message' <<< "$output" >&2 2>/dev/null; then
            exit 1
        fi
        jq -r '.[] | select(.fork | not) | .name' <<< "$output"
        ((page+=1))
    done
}
