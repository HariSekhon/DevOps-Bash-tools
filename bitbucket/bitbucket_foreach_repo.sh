#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: echo workspace={workspace} name={name} repo={repo}
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
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Run a command for each BitBucket repo

All arguments become the command template

WARNING: do not run any command reading from standard input, otherwise it will consume the workspace/user/repo names and exit after the first iteration

The command template replaces the following for convenience in each iteration:

{workspace}   =>   the workspace the repo is in
{name}        =>   the repo name without the workspace prefix
{repo}        =>   the repo name with the workspace prefix

eg.
    ${0##*/} echo user={user} name={name} repo={repo}
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<command> <args>"

help_usage "$@"

min_args 1 "$@"

get_repos(){
    get_workspaces |
    while read -r workspace; do
        get_workspace_repos "$workspace"
    done
}

get_workspaces(){
    local page=1
    while true; do
        if ! output="$("$srcdir/bitbucket_api.sh" "/workspaces?page=$page&pagelen=100")"; then
            echo "ERROR" >&2
            exit 1
        fi
        if [ -z "$(jq '.values[]' <<< "$output")" ]; then
            break
        fi
        jq -r '.values[].slug' <<< "$output"
        ((page+=1))
    done
}

get_workspace_repos(){
    local workspace="$1"
    local page=1
    while true; do
        if ! output="$("$srcdir/bitbucket_api.sh" "/repositories/$workspace?page=$page&pagelen=100")"; then
            echo "ERROR" >&2
            exit 1
        fi
        if [ -z "$(jq '.values[]' <<< "$output")" ]; then
            break
        fi
        jq -r '.values[] | [.workspace.slug, .name, .full_name] | @tsv' <<< "$output"
        ((page+=1))
    done
}

get_repos |
while read -r workspace name repo; do
    echo "# ============================================================================ #" >&2
    echo "# $repo" >&2
    echo "# ============================================================================ #" >&2
    echo >&2
    cmd=("$@")
    cmd=("${cmd[@]//\{workspace\}/$workspace}")
    cmd=("${cmd[@]//\{name\}/$name}")
    cmd=("${cmd[@]//\{repo\}/$repo}")
    # need eval'ing to able to inline quoted script
    # shellcheck disable=SC2294
    eval "${cmd[@]}"
    echo >&2
done
