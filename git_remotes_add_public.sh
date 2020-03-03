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

# Sets up alternative remotes to one or more of the major public Git Repos - GitHub, GitLab or Bitbucket
# for the local checkout so that you can push to them easily
#
# See Also:
#
# git_set_multi_origin.sh    - for push to all
# git_sync_repos_upstream.sh - for sync'ing all repos to another provider

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

usage(){
    echo "usage: ${0##*/} github|gitlab|bitbucket|all"
    exit 3
}

for arg; do
    case "$arg" in
        -*) usage
            ;;
    esac
done

if [ $# -ne 1 ]; then
    usage
fi

name="${1:-}"

if [ -z "$name" ]; then
    usage
fi

add_remote_repo(){
    local name="$1"
    local domain
    if git remote -v | grep -Eq "^${name}[[:space:]]"; then
        echo "$name remote already configured, skipping..."
        return 0
    fi
    if [ "$name" = "github" ]; then
        domain=github.com
    elif [ "$name" = "gitlab" ]; then
        domain=gitlab.com
    elif [ "$name" = "bitbucket" ]; then
        domain=bitbucket.org
    fi
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
    #echo "pulling from $name to merge if necessary"
    #git pull --no-edit "$name" master
    #echo "pushing to $name remote"
    #git push "$name" master
}

if [ "$name" = "github" ] ||
   [ "$name" = "gitlab" ] ||
   [ "$name" = "bitbucket" ]; then
    add_remote_repo "$name"
elif [ "$name" = "all" ]; then
    for name in github gitlab bitbucket; do
        add_remote_repo "$name"
    done
else
    usage
fi
