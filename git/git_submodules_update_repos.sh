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

git_url="${GIT_URL:-https://github.com}"

git_base_dir=~/github

mkdir -pv "$git_base_dir"

cd "$git_base_dir"

repofile="$srcdir/../setup/repos.txt"

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
    echo "Updating Git submodules"
    echo
    for repo in $repolist; do
        repo_dir="${repo##*/}"
        repo_dir="${repo_dir##*:}"
        repo="${repo%%:*}"
        if ! echo "$repo" | grep -q "/"; then
            repo="HariSekhon/$repo"
        fi
        echo "========================================"
        echo "Updating $repo"
        echo "========================================"
        if ! [ -d "$repo_dir" ]; then
            git clone "$git_url/$repo" "$repo_dir"
        fi
        pushd "$repo_dir"
        # make update does git pull but if that mechanism is broken then this first git pull will allow the repo to self-fix itself
        git pull --no-edit
        git submodule update --init --remote --recursive --force ||
        for submodule in $(git submodule | awk '{print $2}'); do
            if [ -d "$submodule" ] && ! [ -L "$submodule" ]; then
                pushd "$submodule" || continue
                git stash
                default_branch="$(default_branch)"
                git checkout "$default_branch"
                git pull --no-edit ||
                git reset --hard origin/"$default_branch"
                git submodule update
                popd
            fi
            echo
        done
        for submodule in $(git submodule | awk '{print $2}'); do
            echo "committing latest hashref for submodule $submodule"
            git ci -m "updated submodule $submodule" "$submodule" || :
            echo
        done
        echo
        if [ -z "${NO_PUSH:-}" ]; then
            if [ -z "${NO_REVIEW_PUSH:-}" ]; then
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
