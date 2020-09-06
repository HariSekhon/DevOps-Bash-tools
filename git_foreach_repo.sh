#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: echo {repo} is found at {dir}
#
#  Author: Hari Sekhon
#  Date: 2016-01-17 12:14:06 +0000 (Sun, 17 Jan 2016)
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
srcdir="$(cd "$(dirname "$0")" && pwd)"

# access to useful functions and aliases
# shellcheck disable=SC1090
. "$srcdir/.bash.d/aliases.sh"
#
# shellcheck disable=SC1090
. "$srcdir/.bash.d/functions.sh"
#
# shellcheck disable=SC1090
. "$srcdir/.bash.d/git.sh"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Run a command against all GitHub repos while changing to their directories on disk

Any repos which are not checked out locally adjacent to this repo are skipped

All arguments become the command template

The command template replaces the following for convenience in each iteration:

{repo} - with the repo name (eg. HariSekhon/DevOps-Bash-tools)
{dir}  - with the directory on disk (eg. /Users/hari/github/bash-tools)

eg. ${0##*/} 'echo {repo} is found at {dir}'

or more usefully when chained with the other adjacent github_*.sh / gitlab_*.sh scripts
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<command> <args>"

help_usage "$@"

min_args 1 "$@"

#git_url="${GIT_URL:-https://github.com}"

#git_base_dir=~/github

#mkdir -pv "$git_base_dir"

#cd "$git_base_dir"

opts="${OPTS:-}"
if [ -z "${NO_TEST:-}" ]; then
    opts="$opts test"
fi

repofile="$srcdir/setup/repos.txt"

repolist="${REPOS:-}"
if [ -n "$repolist" ]; then
    :
elif [ -f "$repofile" ]; then
    log "processing repos from file: $repofile" >&2
    repolist="$(sed 's/#.*//; /^[[:space:]]*$/d' < "$repofile")"
else
    log "fetching repos from GitHub repo list" >&2
    repolist="$(curl -sSL https://raw.githubusercontent.com/HariSekhon/bash-tools/master/setup/repos.txt | sed 's/#.*//')"
fi

execute_repo(){
    local repo="$1"
    local cmd="${*:2}"
    if ! echo "$repo" | grep -q "/"; then
        repo="HariSekhon/$repo"
    fi
    repo_dir="${repo##*/}"
    repo_dir="${repo_dir##*:}"
    repo_dir="$srcdir/../$repo_dir"
    repo="${repo%%:*}"
    if ! [ -d "$repo_dir" ]; then
        #git clone "$git_url/$repo" "$repo_dir"
        return
    fi
    pushd "$repo_dir" >/dev/null
    repo_dir="$PWD"
    if [ -z "${GIT_FOREACH_REPO_NO_HEADERS:-}" ]; then
        echo "# ============================================================================ #" >&2
        echo "# $repo - $repo_dir" >&2
        echo "# ============================================================================ #" >&2
    fi
    cmd="${cmd//\{repo\}/$repo}"
    cmd="${cmd//\{dir\}/$repo_dir}"
    eval "$cmd"
    if [[ "$cmd" =~ github_.*.sh|gitlab_.*.sh|bitbucket_*.sh ]]; then
        # throttle hitting the GitHub / GitLab / Bitbucket APIs too often as they may error out
        sleep 0.05
    fi
    popd >/dev/null
    if [ -z "${GIT_FOREACH_REPO_NO_HEADERS:-}" ]; then
        echo >&2
    fi
}

for repo in $repolist; do
    execute_repo "$repo" "$@"
done
