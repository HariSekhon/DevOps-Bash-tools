#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
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
srcdir="$(dirname "$0")"

git_url="${GIT_URL:-https://github.com}"

run(){
    local repofile="$1"
    echo "processing repos from file: $repofile"
    while read -r repo; do
        repo_dir="${repo##*:}"
        repo_dir="${repo_dir##*/}"
        repo="${repo%%:*}"
        if ! echo "$repo" | grep -q "/"; then
            repo="HariSekhon/$repo"
        fi
        if [ -d "$repo_dir" ]; then
            pushd "$repo_dir"
            # make update does git pull but if that mechanism is broken then this first git pull will allow the repo to self-fix itself
            git pull
            if [ -n "${QUICK:-}" ] ||
               [ -n "${NOBUILD:-}" ] ||
               [ -n "${NO_BUILD:-}" ]; then
                make update-no-recompile || exit 1
            else
                make update
            fi
            popd
        else
            git clone "$git_url/$repo" "$repo_dir"
        fi
    done < <(sed 's/#.*//; /^[[:space:]]*$/d' < "$repofile")
}

if [ $# -gt 0 ]; then
    for x in "$@"; do
        run "$x"
    done
else
    run "$srcdir/setup/repolist.txt"
fi
