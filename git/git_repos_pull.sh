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

# Pulls all my Git repos listed in setup/repos.txt to ~/github/

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "${GIT_HTTPS:-}" ]; then
    git_url="${GIT_URL:-https://github.com/}"
    if [ -n "${GITHUB_TOKEN:-}" ] && ! [[ "$git_url" =~ @ ]]; then
        git_url="https://$GITHUB_TOKEN@${git_url#https://}"
    fi
else
    git_url="${GIT_URL:-git@github.com:}"
fi

git_base_dir=~/github

mkdir -pv "$git_base_dir"

cd "$git_base_dir"

sed 's/#.*//; s/:/ /; /^[[:space:]]*$/d' "$srcdir/../setup/repos.txt" |
while read -r repo dir; do
    if [ -z "$dir" ]; then
        dir="$repo"
    fi
    if ! echo "$repo" | grep -q "/"; then
        repo="HariSekhon/$repo"
    fi
    if [ -d "$dir" ]; then
        pushd "$dir"
        # make update does git pull but if that mechanism is broken then this first git pull will allow the repo to self-fix itself
        git pull --no-edit
        popd
    else
        git clone "${git_url}${repo}" "$dir"
    fi
done
