#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
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

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/git.sh"

repofile="$srcdir/../setup/repos.txt"
repofile="$(readlink -f "$repofile")"

# shellcheck disable=SC2034,SC2154
usage_description="
Updates all Git repos given as args or listed in file:

    $repofile


Uses adjacent script:

    git_submodules_update.sh


Environment Variables:

    GIT_BASE_DIR - default: $HOME/github - checks out the repos to this location if they are not already present

    GIT_URL - default: https://github.com

    GIT_OWNER - default: HariSekhon - used only when omitting the owner/ prefix of owner/repo
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

#num_args 0 "$@"

git_url="${GIT_URL:-https://github.com}"

HOME="${HOME:-$(cd && pwd)}"

git_base_dir="${GIT_BASE_DIR:-$HOME/github}"

git_owner="${GIT_OWNER:-HariSekhon}"

mkdir -pv "$git_base_dir"

cd "$git_base_dir"

if [ $# -gt 0 ]; then
    repolist="$*"
else
    repolist="${*:-${REPOS:-}}"
    if [ -n "$repolist" ]; then
        :
    elif [ -f "$repofile" ]; then
        echo "processing repos from file: $repofile"
        repolist="$(sed 's/#.*//; /^[[:space:]]*$/d' < "$repofile")"
    else
        echo "fetching repos from GitHub repo list"
        repolist="$(curl -sSL https://raw.githubusercontent.com/HariSekhon/bash-tools/master/setup/repos.txt | sed 's/#.*//')"
    fi
fi

run(){
    local repolist="$*"
    timestamp "Updating Git submodules for all repos: $repolist"
    echo >&2
    for repo in $repolist; do
        repo_dir="${repo##*/}"
        repo_dir="${repo_dir##*:}"
        repo="${repo%%:*}"
        if ! echo "$repo" | grep -q "/"; then
            repo="$git_owner/$repo"
        fi
        echo "========================================"
        timestamp "Updating $repo"
        echo "========================================"
        if ! [ -d "$repo_dir" ]; then
            git clone "$git_url/$repo" "$repo_dir"
        fi
        pushd "$repo_dir"
        "$srcdir/git_submodules_update.sh"
        # make update does git pull but if that mechanism is broken then this first git pull will allow the repo to self-fix itself
        #git pull --no-edit
        #git submodule update --init --remote --recursive --force ||
        #for submodule in $(git submodule | awk '{print $2}'); do
        #    if [ -d "$submodule" ] && ! [ -L "$submodule" ]; then
        #        pushd "$submodule" || continue
        #        git stash
        #        default_branch="$(default_branch)"
        #        git checkout "$default_branch"
        #        git pull --no-edit ||
        #        git reset --hard origin/"$default_branch"
        #        git submodule update
        #        popd
        #    fi
        #    echo
        #done
        #for submodule in $(git submodule | awk '{print $2}'); do
        #    echo "committing latest hashref for submodule $submodule"
        #    git ci -m "updated submodule $submodule" "$submodule" || :
        #    echo
        #done
        echo
        if [ -z "${NO_PUSH:-}" ]; then
            if [ -n "${REVIEW_PUSH:-}" ]; then
                "$srcdir/git_review_push.sh"
            else
                git push
            fi
        fi
        popd
        echo
    done
}

run "$repolist"
