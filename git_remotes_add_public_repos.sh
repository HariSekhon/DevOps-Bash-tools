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
srcdir="$(dirname "${BASH_SOURCE[0]}")"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Sets up alternative remotes to one or more of the major public Git Repos - GitHub, GitLab, Bitbucket or Azure DevOps
for the local checkout so that you can push to them easily

See Also:

git_remotes_set_multi_origin.sh  - for push to all
git_sync_repos_upstream.sh       - for sync'ing all repos to another provider
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="github|gitlab|bitbucket|azure|all"

help_usage "$@"

min_args 1 "$@"

name="${1:-}"

if [ -z "$name" ]; then
    usage
fi

add_remote_repo(){
    local name="$1"
    local domain
    # used by log statements
    # shellcheck disable=SC2034
    local VERBOSE=1
    if git remote -v | grep -Eq "^${name}[[:space:]]"; then
        log "$name remote already configured, skipping..."
        return 0
    fi
    if [ "$name" = "github" ]; then
        domain=github.com
        user="${GITHUB_USER:-}"
        token="${GITHUB_TOKEN:-${GITHUB_PASSWORD:-}}"
    elif [ "$name" = "gitlab" ]; then
        domain=gitlab.com
        user="${GITLAB_USER:-}"
        token="${GITLAB_TOKEN:-${GITLAB_PASSWORD:-}}"
    elif [ "$name" = "bitbucket" ]; then
        domain=bitbucket.org
        user="${BITBUCKET_USER:-}"
        token="${BITBUCKET_TOKEN:-${BITBUCKET_PASSWORD:-}}"
    elif [ "$name" = "azure" ]; then
        domain=dev.azure.com
        user="${AZURE_DEVOPS_USER:-}"
        # XXX: you should set $AZURE_DEVOPS_PROJECT in your environment or call your project GitHub as I have - there is no portable way to infer this from other repos since they don't have this hierarchy level
        project="${AZURE_DEVOPS_PROJECT:-GitHub}"
        token="${AZURE_DEVOPS_TOKEN:-${AZURE_DEVOPS_PASSWORD:-}}"
    fi
    log "$name remote not configured, configuring..."
    set +o pipefail
    url="$(git remote -v | awk '{print $2}' | grep -Ei "$domain" | head -n 1)"
    if [ -n "$url" ]; then
        log "copied existing remote url for $name as is including any access tokens to named remote $name"
    else
        url="$(git remote -v | awk '{print $2}' | grep -Ei 'bitbucket.org|github.com|gitlab.com|dev.azure.com' | head -n 1 | perl -pe "s/^((\\w+:\\/\\/)?(git@)?)(.+@)?[^\\/:]+/\$1$domain/")"
        # XXX: Azure DevOps has non-uniform URLs compared to the 3 main Git repos
        if [ "$name" = "azure" ]; then
            url="${url/git@dev.azure.com/git@ssh.dev.azure.com}"
            if [[ "$url" =~ ssh.dev.azure.com ]]; then
                url="${url/:/:v3\/}"
                # XXX: lowercase username and inject $project just before the repo name to conform to weird Azure DevOps urls
                url="$(perl -pe "s/(\\/[^\\/]+)(\\/[^\\/]+)$/\\L\$1\\E\\/$project\$2/" <<< "$url")"
            else # https
                url="$(perl -pe "s/(\\/[^\\/]+)(\\/[^\\/]+)$/\\L\$1\\E\\/$project\\/_git\$2/" <<< "$url")"
            fi
        fi
        # shouldn't really print full url below in case it has an http access token in it that we don't want appearing as plaintext on the screen
        log "inferring $name URL to be $url"
        log "adding remote $name with url $url"
        if [[ "$url" =~ ^https:// ]]; then
            if [ -n "${user:-}" ] && [ -n "${token:-}" ]; then
                log "added authentication credentials from environment"
                url="https://$user:$token@${url##https://}"
            fi
        elif ! [[ "$url" =~ git@ ]]; then
            url="git@${url##ssh:\/\/}"
        fi
    fi
    set -o pipefail
    git remote add "$name" "$url"
    #log "pulling from $name to merge if necessary"
    #git pull --no-edit "$name" master
    #log "pushing to $name remote"
    #git push "$name" master
}

if [ "$name" = "github" ] ||
   [ "$name" = "gitlab" ] ||
   [ "$name" = "bitbucket" ] ||
   [ "$name" = "azure" ]; then
    add_remote_repo "$name"
    echo >&2
    git remote -v | sed 's|://.*@|://|'
elif [ "$name" = "all" ]; then
    for name in github gitlab bitbucket azure; do
        add_remote_repo "$name"
    done
    echo >&2
    git remote -v | sed 's|://.*@|://|'
else
    usage
fi
