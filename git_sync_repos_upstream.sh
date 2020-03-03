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

# Syncs all adjacent repos from setup/repolist.txt to one of the upstreams GitHub / GitLab / BitBucket
#
# another trick would be to set the remote origin to contain all 3 URLs so each push goes to all 3 repos every time
#
# eg.
#
# git remote set-url --add origin <url>
#
# git remote set-url --add origin https://bitbucket.org/HariSekhon/DevOps-Bash-tools

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

cd "$srcdir"

name="${1:-}"

usage(){
    echo "usage: ${0##*/} github|gitlab|bitbucket"
    exit 3
}

if [ -z "$name" ]; then
    usage
fi

if [ "$name" = "github" ]; then
    domain=github.com
elif [ "$name" = "gitlab" ]; then
    domain=gitlab.com
elif [ "$name" = "bitbucket" ]; then
    domain=bitbucket.org
else
    usage
fi

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
    echo "Sync'ing repo $repo to $name"
    name="${name%.*}"
    pushd "$dir" &>/dev/null
    if ! git remote | grep -q "$name"; then
        echo "$name remote not configured, configuring..."
        set +o pipefail
        url="$(git remote -v | awk '{print $2}' | grep -Ei "$domain" | head -n 1)"
        if [ -n "$url" ]; then
            echo "copied existing remote url for $name as is including any access tokens to named remote $name"
        else
            url="$(git remote -v | awk '{print $2}' | grep -Ei 'bitbucket.org|github.com|gitlab.com' | head -n 1 | perl -pe "s/^(\\w+:\\/\\/)[^\\/]+/\$1$domain/")"
            echo "inferring $name URL to be $url"
            # don't put this below and it'd print your access token to screen from existing remote
            echo "adding remote $name with url $url"
        fi
        set -o pipefail
        git remote add "$name" "$url"
    fi
    echo "pulling from $name to merge if necessary"
    git pull --no-edit "$name" master
    echo "pushing to $name remote"
    git push "$name" master
    popd &>/dev/null
done
