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

# Sets up multi-origin to one or more of the major public Git repos - GitHub, GitLab, Bitbucket
# for the local checkout so that each push pushes to all 3 upstream repos
#
# See Also:
#
# git_remotes_add_public_repos.sh  - create alternative remotes for easy individual pushes
# git_sync_repos_upstream.sh       - for sync'ing all repos to another provider

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

add_origin_url(){
    local name="$1"
    local domain
    if [ "$name" = "github" ]; then
        domain=github.com
    elif [ "$name" = "gitlab" ]; then
        domain=gitlab.com
    elif [ "$name" = "bitbucket" ]; then
        domain=bitbucket.org
    fi
    if git remote -v | grep -Eq "^origin[[:space:]]+.+$domain"; then
        echo "$name remote already configured in origin, skipping..."
        return 0
    fi
    echo "$name remote not configured in origin, configuring..."
    set +o pipefail
    url="$(git remote -v | awk '{print $2}' | grep -Ei "$domain" | head -n 1)"
    if [ -n "$url" ]; then
        echo "copied existing remote url for $name as is including any access tokens to named remote $name"
    else
        url="$(git remote -v | awk '{print $2}' | grep -Ei 'bitbucket.org|github.com|gitlab.com' | head -n 1 | perl -pe "s/^(\\w+:\\/\\/)[^\\/]+/\$1$domain/")"
        echo "inferring $name URL to be $url"
        # don't put this below and it'd print your access token to screen from existing remote
        echo "adding additional origin remote for $name with url $url"
    fi
    set -o pipefail
    # --push is willing to add duplicates, prefer error out (should never happen as we check for existing remote url)
    #git remote set-url --add --push origin "$url"
    git remote set-url --add origin "$url"
}

if [ "$name" = "github" ] ||
   [ "$name" = "gitlab" ] ||
   [ "$name" = "bitbucket" ]; then
    add_origin_url "$name"
    # TMI
    #git remote show origin
    git remote -v | grep '^origin' | sed 's|://.*@|://|'
elif [ "$name" = "all" ]; then
    for name in github gitlab bitbucket; do
        add_origin_url "$name"
    done
    #git remote show origin
    git remote -v | grep '^origin' | sed 's|://.*@|://|'
else
    usage
fi
