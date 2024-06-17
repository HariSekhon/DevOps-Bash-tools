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
srcdir_gitlab_lib="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir_gitlab_lib/utils.sh"

# shellcheck disable=SC1090,SC1091
. "$srcdir_gitlab_lib/git.sh"

# shellcheck disable=SC2034
usage_gitlab_cli_required="Requires GitLab CLI to be installed and configured, as well as jq"

# ERE format regex
gitlab_pull_request_url_regex='https://gitlab.com/[[:alnum:]/_-]+/pull/[[:digit:]]+'

get_gitlab_repo(){
    git remote -v 2>/dev/null |
    grep -E "gitlab\.[[:alnum:].-]+[/:]" |
    awk '{print $2}' |
    head -n1 |
    sed '
        s,.*://,,;
        s/.*@//;
        s/[^:/]*[:/]//;
        s/\.git$//;
        s|^/||;
    '
}

is_gitlab_origin(){
    git remote -v |
    # permitting generic domain regex for those self-hosting their own gitlab servers
    grep -Eq "^origin.*gitlab\.[[:alnum:].-]+[/:]"
}

check_gitlab_origin(){
    if ! is_gitlab_origin; then
        die 'GitLab is not set as remote origin in current repo!'
    fi
}

gitlab_origin_owner_repo(){
    local owner_repo
    owner_repo="$(
        git remote -v |
        grep -Em1 '^origin.*gitlab\.[[:alnum:].-]+[/:]' |
        sed '
            s|.*gitlab\.[[:alnum:].-]*[:/]||;
            s/\.git.*//;
            s/[[:space:]].*//
        ' ||
        :
    )"
    is_gitlab_owner_repo "$owner_repo" || die "<owner>/<repo> '$owner_repo' does not match expected format"
    echo "$owner_repo"
}

is_gitlab_owner_repo(){
    local repo="$1"
    # .gitlab repo is valid
    [[ "$repo" =~ ^[[:alnum:]-]+/[[:alnum:]._-]+$ ]]
}

get_gitlab_user(){
    if [ -n "${GITLAB_USER:-}" ]; then
        echo "$GITLAB_USER"
    else
        # get currently authenticated user
        "$srcdir_gitlab_lib/../gitlab/gitlab_api.sh" /user | jq -r .username
    fi
}

#gitlab_result_has_more_pages(){
#    local output="$1"
#    if [ -z "$(jq '.[]' <<< "$output")" ]; then
#        return 1
#    elif jq -r '.message' <<< "$output" >&2 2>/dev/null; then
#        exit 1
#    fi
#    return 0
#}
#
#get_gitlab_repos(){
#    local owner="${1:-}"
#    if [ -z "$owner" ]; then
#        owner="$(get_gitlab_user)"
#    fi
#    local is_org="${2:-}"
#    local filter="${3:-.}"
#    local prefix
#    if [ -n "$is_org" ]; then
#        prefix="orgs"
#    else
#        prefix="users"
#    fi
#    local page=1
#    while true; do
#        if ! output="$("$srcdir_gitlab_lib/../gitlab/gitlab_api.sh" "/$prefix/$owner/repos?page=$page&per_page=100")"; then
#            echo "ERROR" >&2
#            exit 1
#        fi
#        if [ -z "$(jq '.[]' <<< "$output")" ]; then
#            break
#        elif jq -r '.message' <<< "$output" >&2 2>/dev/null; then
#            exit 1
#        fi
#        jq_debug_pipe_dump <<< "$output" |
#        jq -r ".[] | select(.fork | not) | $filter | .name"
#        ((page+=1))
#    done
#}
#
#get_gitlab_repo_branches(){
#    local repo="$1"
#    local page=1
#    while true; do
#        if ! output="$("$srcdir_gitlab_lib/../gitlab_api.sh" "/repos/$repo/branches?page=$page&per_page=100")"; then
#            echo "ERROR" >&2
#            exit 1
#        fi
#        if [ -z "$(jq '.[]' <<< "$output")" ]; then
#            break
#        elif jq -r '.message' <<< "$output" >&2 2>/dev/null; then
#            exit 1
#        fi
#        jq_debug_pipe_dump <<< "$output" |
#        jq -r ".[].name"
#        ((page+=1))
#    done
#}
#
#parse_pull_request_url(){
#    local text="$1"
#    grep -Eom1 "$gitlab_pull_request_url_regex" <<< "$text" ||
#    die "Failed to parse GitLab pull request URL"
#}
