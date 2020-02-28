#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-02-13 15:36:35 +0000 (Thu, 13 Feb 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

cd "$srcdir"

sed 's/#.*//; s/:/ /; /^[[:space:]]*$/d' "$srcdir/setup/repolist.txt" |
while read -r repo dir; do
    if [ -z "$dir" ]; then
        dir="$repo"
    fi
    dir="../$dir"
    if ! [ -d "$dir" ]; then
        echo "WARNING: repo dir $dir not found, skipping..."
        continue
    fi
    echo
    echo "Sync'ing repo $repo to BitBucket"
    pushd "$dir" &>/dev/null
    if ! git remote | grep -q bitbucket; then
        echo "BitBucket remote not configured, configuring..."
        bitbucket_url="$(git remote -v | awk '/github.com|gitlab.com/{print $2; exit}' | sed 's,.*.com/,https://bitbucket.org/,')"
        echo "inferring BitBucket URL to be $bitbucket_url"
        echo "adding remote bitbucket with url $bitbucket_url"
        git remote add bitbucket "$bitbucket_url"
    fi
    echo "pulling from BitBucket to merge if necessary"
    git pull --no-edit bitbucket master
    echo "pushing to BitBucket remote"
    git push bitbucket master
    popd &>/dev/null
done
