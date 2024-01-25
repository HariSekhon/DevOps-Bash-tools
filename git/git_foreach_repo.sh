#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: echo owner={owner} repo={repo} is found at dir={dir}
#
#  Author: Hari Sekhon
#  Date: 2016-01-17 12:14:06 +0000 (Sun, 17 Jan 2016)
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

# access to useful functions and aliases
# shellcheck disable=SC1090,SC1091
. "$srcdir/.bash.d/aliases.sh"
#
# shellcheck disable=SC1090,SC1091
. "$srcdir/.bash.d/functions.sh"
#
# shellcheck disable=SC1090,SC1091
. "$srcdir/.bash.d/git.sh"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Run a command against all GitHub repos while changing to their directories on disk

Any repos which are not checked out locally adjacent to this repo are skipped

All arguments become the command template

The command template replaces the following for convenience in each iteration:

{owner} - repo owner eg. HariSekhon
{repo}  - repo name without the user/org prefix (eg. DevOps-Bash-tools)
{dir}   - directory on disk (eg. /Users/hari/github/bash-tools)

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

opts=("${OPTS:-}")
if [ -z "${NO_TEST:-}" ]; then
    opts+=("test")
fi

repofile="$srcdir/../setup/repos.txt"

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
    local owner_repo="$1"
    shift || :
    local cmd=("$@")
    local owner
    local repo="${owner_repo##*/}"
    repo_dir="$repo"
    repo_dir="${repo_dir##*:}"
    repo_dir="$srcdir/../../$repo_dir"
    repo="${repo%%:*}"
    if ! [ -d "$repo_dir" ]; then
        #git clone "$git_url/$repo" "$repo_dir"
        return
    fi
    if grep -q "/" <<< "$owner_repo"; then
        owner="${owner_repo%/*}"
    else
        #owner_repo="HariSekhon/$repo"
        owner="$(cd "$repo_dir"; git remotes | awk '{print $2}' | sed 's|/[^/]*$||; s|/[^/]*/_git||; s|.*[/:]||' | head -n1)"
        if [ -z "$owner" ]; then
            die "Failed to find owner for repo '$repo' at dir '$repo_dir'"
        fi
        owner_repo="$owner/$repo"
    fi
    pushd "$repo_dir" >/dev/null
    repo_dir="$PWD"
    if [ -z "${GIT_FOREACH_REPO_NO_HEADERS:-}" ]; then
        echo "# ============================================================================ #" >&2
        echo "# $owner_repo - $repo_dir" >&2
        echo "# ============================================================================ #" >&2
    fi
    cmd=("${cmd[@]//\{owner\}/$owner}")
    cmd=("${cmd[@]//\{repo\}/$repo}")
    cmd=("${cmd[@]//\{dir\}/$repo_dir}")
    # need eval'ing to able to inline quoted script
    # shellcheck disable=SC2294
    eval "${cmd[@]}"
    if [[ "${cmd[*]}" =~ github_.*.sh|gitlab_.*.sh|bitbucket_*.sh ]]; then
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
