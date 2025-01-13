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

# shellcheck disable=SC1090,SC1091
. "$srcdir_github_lib/utils.sh"

# shellcheck disable=SC1090,SC1091
. "$srcdir_github_lib/git.sh"

# shellcheck disable=SC2034
usage_github_cli_required="Requires GitHub CLI to be installed and configured, as well as jq"

# ERE format regex
github_pull_request_url_regex='https://github.com/[[:alnum:]_-]+/[[:alnum:]_-]+/pull/[[:digit:]]+'
# shellcheck disable=SC2034
github_release_url_regex='https://github.com/[[:alnum:]_-]+/[[:alnum:]_-]+/releases/download/[^/]+/'

get_github_repo(){
    git remote -v 2>/dev/null |
    grep -E "github\.[[:alnum:].-]+[/:]" |
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

is_github_origin(){
    git remote -v |
    # permitting generic domain regex for those self-hosting their own github enterprise servers
    grep -Eq "^origin[[:space:]].+github\.[[:alnum:].-]+[/:]"
}

is_github_fork(){
    local is_fork
    is_fork="$(gh repo view --json isFork -q '.isFork')"
    if [ "$is_fork" = true ]; then
        return 0
    fi
    return 1
}

github_owner_repo(){
    local owner_repo
    owner_repo="$(gh repo view --json owner,name -q '.owner.login + "/" + .name')"
    if ! is_github_owner_repo "$owner_repo"; then
        echo "GitHub owner/repo '$owner_repo' does not match expected format returned in github_owner_repo()" >&2
        return 1
    fi
    echo "$owner_repo"
}

check_github_origin(){
    if ! is_github_origin; then
        die 'GitHub is not set as remote origin in current repo!'
    fi
}

github_origin_owner_repo(){
    local owner_repo
    owner_repo="$(
        git remote -v |
        grep -Em1 '^origin.*github\.[[:alnum:].-]+[/:]' |
        sed '
            s|.*github\.[[:alnum:].-]*[:/]||;
            s/\.git.*//;
            s/[[:space:]].*//
        ' ||
        :
    )"
    if ! is_github_owner_repo "$owner_repo"; then
        echo "GitHub owner/repo '$owner_repo' does not match expected format returned in github_origin_owner_repo()" >&2
        return 1
    fi
    echo "$owner_repo"
}

github_repo_set_default(){
    # this command has poor behaviour - returns exit code 0 whether set or not, and the error string is sent to stdout instead of stderr, although it returns blank when in a pipe
    #
    #   https://github.com/cli/cli/issues/9398
    #
    # returns blank when in a pipe
    if ! gh repo set-default --view | grep -q '.'; then
        local origin
        origin="$(git remote -v | awk '/^origin[[:space:]]/{print $2; exit}')"
        if [ -n "$origin" ]; then
            timestamp "GitHub CLI setting repo default to '$origin'"
            gh repo set-default "$origin"
        else
            gh repo set-default --view >&2
            echo "GitHub CLI default repo not set" >&2
            return 1
        fi
    fi
}

github_upstream_owner_repo(){
    local owner_repo
    github_repo_set_default
    owner_repo="$(gh repo view --json parent | jq -r '.parent | .owner.login + "/" + .name')"
    if [ "$owner_repo" = / ]; then
        echo "Failed to determine upstream owner/repo" >&2
        return 1
    elif ! is_github_owner_repo "$owner_repo"; then
        echo "GitHub upstream owner/repo '$owner_repo' does not match expected format" >&2
        return 1
    fi
    echo "$owner_repo"
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
        "$srcdir_github_lib/../github/github_api.sh" /user | jq -r .login
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

# pass owner as first arg and then any other --options
get_github_repo_urls(){
    local owner="${1:-}"
    gh repo list "$@" \
        --limit 9999999 \
        --json url \
        --jq '.[].url'
        # pass these from the client to retain flexibility
        #--visibility public \
        #--source \
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
        if ! output="$("$srcdir_github_lib/../github/github_api.sh" "/$prefix/$owner/repos?page=$page&per_page=100")"; then
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
        if ! output="$("$srcdir_github_lib/../github/github_api.sh" "/repos/$repo/branches?page=$page&per_page=100")"; then
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

parse_pull_request_url(){
    local text="$1"
    grep -Eom1 "$github_pull_request_url_regex" <<< "$text" ||
    die "Failed to parse GitHub pull request URL"
}
