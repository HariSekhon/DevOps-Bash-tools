#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-02-13 15:36:35 +0000 (Thu, 13 Feb 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/git.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Syncs all adjacent repos from setup/repos.txt to one of the upstreams GitHub / GitLab / BitBucket / Azure DevOps

Another trick would be to set the remote origin to contain all 3 URLs so each push goes to all 3 repos every time

eg.

    git remote set-url --add origin <url>

    git remote set-url --add origin https://bitbucket.org/HariSekhon/DevOps-Bash-tools

See git_remotes_set_multi_origin.sh for an auto-inferred implementation of this
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="github|gitlab|bitbucket|azure"

name="${1:-}"

if [ -z "$name" ]; then
    usage
fi

if [ "$name" = "github" ]; then
    domain=github.com
elif [ "$name" = "gitlab" ]; then
    domain=gitlab.com
elif [ "$name" = "bitbucket" ]; then
    domain=bitbucket.org
elif [ "$name" = "azure" ]; then
    domain=dev.azure.com
else
    usage
fi

#sed 's/#.*//; s/:/ /; /^[[:space:]]*$/d' "$srcdir/../setup/repos.txt" |
echo "DevOps-Golang-tools go-tools" |
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
            url="$(git remote -v | awk '{print $2}' | grep -Ei 'bitbucket.org|github.com|gitlab.com|dev.azure.com' | head -n 1 | perl -pe "s/^((\\w+:\\/\\/)?(git@)?)[^\\/:]+/\$1$domain/")"
            # XXX: Azure DevOps has non-uniform URLs compared to the 3 main Git repos
            if [ "$name" = "azure" ]; then
                url="$(git_to_azure_url "$url")"
            else
                # undo weird Azure DevOps url components if we happen to infer URL from an Azure DevOps url
                url="$(azure_to_git_url "$url")"
            fi
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
