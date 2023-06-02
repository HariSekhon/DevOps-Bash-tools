#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: echo user={user} name={name} repo={project}
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
Run a command for each GitLab project / repo

All arguments become the command template

WARNING: do not run any command reading from standard input, otherwise it will consume the repo names and exit after the first iteration

The command template replaces the following for convenience in each iteration:

{username}, {user}    =>    your authenticated user
{name}                =>    the repo / project name without the user prefix
{project}, {repo}     =>    the repo / project name with the user prefix

eg.
    ${0##*/} echo user={user} name={name} repo={project}
    ${0##*/} echo user={user} name={name} repo={repo}
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<command> <args>"

help_usage "$@"

min_args 1 "$@"

if [ -n "${GITLAB_USER:-}" ]; then
    user="$GITLAB_USER"
else
    # get currently authenticated user
    user="$("$srcdir/gitlab_api.sh" /user | jq -r .username)"
fi

get_repos(){
    local page=1
    while true; do
        if ! output="$("$srcdir/gitlab_api.sh" "/users/$user/projects?page=$page&per_page=100")"; then
            echo "ERROR" >&2
            exit 1
        fi
        if [ -z "$(jq '.[]' <<< "$output")" ]; then
            break
        elif jq -r '.message' <<< "$output" >&2 2>/dev/null; then
            exit 1
        fi
        jq -r '.[] | select(.fork | not) | [.path, .path_with_namespace] | @tsv' <<< "$output"
        ((page+=1))
    done
}

get_repos |
while read -r name repo; do
    echo "# ============================================================================ #" >&2
    echo "# $repo" >&2
    echo "# ============================================================================ #" >&2
    echo >&2
    cmd=("$@")
    cmd=("${cmd[@]//\{username\}/$user}")
    cmd=("${cmd[@]//\{user\}/$user}")
    cmd=("${cmd[@]//\{project\}/$repo}")
    cmd=("${cmd[@]//\{repo\}/$repo}")
    cmd=("${cmd[@]//\{name\}/$name}")
    # need eval'ing to able to inline quoted script
    # shellcheck disable=SC2294
    eval "${cmd[@]}"
    echo >&2
done
