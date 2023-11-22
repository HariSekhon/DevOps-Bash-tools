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
Sets up Git multi-origin to one or more of the major public Git repos - GitHub, GitLab, Bitbucket or Azure DevOps
for the local checkout so that each push sync's to multiple provider's repos

To pull from multiple Repo providers in a single command:

    git pull --all

see the related script:

    git_remotes_add_origin_providers.sh

See Also:

    git_remotes_add_origin_providers.sh  - creates remotes for easy individual pull/pushes or git pull --all
    git_sync_repos_upstream.sh           - for sync'ing all repos to another provider
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="github|gitlab|bitbucket|azure|all"

help_usage "$@"

no_more_opts "$@"

min_args 1 "$@"

add_origin_url(){
    local name="$1"
    local domain="unconfigured"
    # loads domain and variables user and token if available via environment variables
    git_provider_env "$name"
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
        url="$(
            git remote -v |
            awk '{print $2}' |
            grep -Ei 'bitbucket.org|github.com|gitlab.com|dev.azure.com' |
            head -n 1 |
            perl -pe "
                s/^(\\w+:\\/\\/)[^\\/]+/\$1$domain/;
                s/^(git@)[^:]+/\$1$domain/
            "
        )"
        # XXX: Azure DevOps has non-uniform URLs compared to the 3 main Git repos
        if [ "$name" = "azure" ]; then
            url="$(git_to_azure_url "$url")"
        else
            # undo weird Azure DevOps url components if we happen to infer URL from an Azure DevOps url
            url="$(azure_to_git_url "$url")"
        fi
        # XXX: shouldn't really print full url below in case it has an http access token in it that we don't want appearing as plaintext on the screen, but git remote -v will print it later on anyway
        echo "inferring $name URL to be $url"
        echo "adding additional origin remote for $name with url $url"
    fi
    set -o pipefail
    # --push is willing to add duplicates, prefer error out (should never happen as we check for existing remote url)
    #git remote set-url --add --push origin "$url"
    git remote set-url --add origin "$url"
}

for name in "$@"; do
    if [ "$name" = "github" ] ||
       [ "$name" = "gitlab" ] ||
       [ "$name" = "bitbucket" ] ||
       [ "$name" = "azure" ]; then
        add_origin_url "$name"
        echo >&2
        # TMI
        #git remote show origin
        git remote -v | grep '^origin' | sed 's|://.*@|://|'
    elif [ "$name" = "all" ]; then
        for name2 in github gitlab bitbucket azure; do
            add_origin_url "$name2"
        done
        echo >&2
        #git remote show origin
        git remote -v | grep '^origin' | sed 's|://.*@|://|'
    else
        usage
    fi
done
