#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-02-09 02:48:01 +0000 (Fri, 09 Feb 2024)
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

# shellcheck disable=SC2034,SC2154
usage_description="
Creates Git credential helper config for the major Git hosting providers if their tokens are found in the local environment

Support GitHub, GitLab, Bitbucket and Azure DevOps

Checks for the following environment variables and if they're set then set up the credentials helper for dynamic HTTPS credentials

This is useful because Azure DevOps personal access tokens have a maximum expiry of 1 year so you don't want to hardcode them across two dozen git repo checkouts but rather all inherit the auth from the environment

If you travel and lot, sometimes you can only git push through HTTPS due to egress port filtering in hotels or corporate firewalls

When combined with the adjacent scripts

    git_remotes_set_ssh_to_https.sh
        and
    git_foreach_repo.sh

this allows you to quickly switch many git repo checkouts from SSH to HTTPS and have them all inherit the environment auth tokens

If the GIT_GLOBAL_CONFIG environment variable is set to any value, then sets it at the global user config level instead of in the local repo

If no provider is found, checks for the following environment variables and sets them automatically in the local git repo if they're both found

GitHub:

    GITHUB_USER
    GITHUB_TOKEN / GH_TOKEN

GitLab:

    GITLAB_USER
    GITLAB_TOKEN

Bitbucket:

    BITBUCKET_USER
    BITBUCKET_TOKEN

Azure DevOps:

    AZURE_DEVOPS_USER
    AZURE_DEVOPS_TOKEN
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<github|gitlab|bitbucket|azure|all>]"

help_usage "$@"

max_args 1 "$@"

provider="${1:-all}"

#global="${2:+--global}"
global="${GIT_GLOBAL_CONFIG:+--global}"

github_cred_helper(){
    # GH_TOKEN is higher precedence in GitHub CLI so do the same here for consistency to avoid non-intuitive auth problems where one works and the other doesn't using different tokens
    if [ -n "${GH_TOKEN:-${GITHUB_TOKEN:-}}" ]; then
        timestamp "Setting credential helper for GitHub"
        # shellcheck disable=SC2016,SC2086
        for fqdn in github.com gist.github.com; do
            # username is not needed in practice when using a token, neither on github.com, nor on gist.github.com after the first time for https://<username>@github.com/...
            # but put it back in because that first time leads to problems
            #git config $global "credential.https://$fqdn.helper" '!f() { sleep 1; echo "password=${GH_TOKEN:-${GITHUB_TOKEN}}"; }; f'
            # env vars need to be evaluated dynamically not here
            # $global must not be quoted because when it is empty this will break the command with a '' arg
            git config $global credential.https://github.com.helper '!f() { sleep 1; echo "username=${GITHUB_USER}"; echo "password=${GH_TOKEN:-${GITHUB_TOKEN}}"; }; f'
        done
    else
        timestamp "NOT setting credential helper for GitHub since \$GH_TOKEN / \$GITHUB_TOKEN not found in environment"
    fi
}

gitlab_cred_helper(){
    #if [ -n "${GITHUB_USER:-}" ]; then
        if [ -n "${GITLAB_TOKEN:-}" ]; then
            timestamp "Setting credential helper for GitLab"
            # shellcheck disable=SC2016,SC2086
            #git config credential.https://gitlab.com.helper '!f() { sleep 1; echo "username=${GITLAB_USER}"; echo "password=${GITLAB_TOKEN}"; }; f'
            # $global must not be quoted because when it is empty this will break the command with a '' arg
            git config $global credential.https://gitlab.com.helper '!f() { sleep 1; echo "password=${GITLAB_TOKEN}"; }; f'
        else
            timestamp "NOT setting credential helper for GitLab since \$GITLAB_TOKEN not found in environment"
        fi
    #fi
}

bitbucket_cred_helper(){
    #if [ -n "${GITHUB_USER:-}" ]; then
        if [ -n "${BITBUCKET_TOKEN:-}" ]; then
            timestamp "Setting credential helper for Bitbucket"
            # shellcheck disable=SC2016,SC2086
            #git config credential.https://bitbucket.org.helper '!f() { sleep 1; echo "username=${BITBUCKET_USER}"; echo "password=${BITBUCKET_TOKEN}"; }; f'
            # $global must not be quoted because when it is empty this will break the command with a '' arg
            git config $global credential.https://bitbucket.org.helper '!f() { sleep 1; echo "password=${BITBUCKET_TOKEN}"; }; f'
        else
            timestamp "NOT setting credential helper for Bitbucket since \$BITBUCKET_TOKEN not found in environment"
        fi
    #fi
}

azure_devops_cred_helper(){
    #if [ -n "${GITHUB_USER:-}" ]; then
        if [ -n "${AZURE_DEVOPS_TOKEN:-}" ]; then
            timestamp "Setting credential helper for Azure DevOps"
            # shellcheck disable=SC2016,SC2086
            #git config credential.https://dev.azure.com.helper '!f() { sleep 1; echo "username=${AZURE_DEVOPS_USER}"; echo "password=${AZURE_DEVOPS_TOKEN}"; }; f'
            # $global must not be quoted because when it is empty this will break the command with a '' arg
            git config $global credential.https://dev.azure.com.helper '!f() { sleep 1; echo "password=${AZURE_DEVOPS_TOKEN}"; }; f'
        else
            timestamp "NOT setting credential helper for Azure DevOps since \$AZURE_DEVOPS_TOKEN not found in environment"
        fi
    #fi
}

if [ "$provider" = all ]; then
    github_cred_helper
    gitlab_cred_helper
    bitbucket_cred_helper
    azure_devops_cred_helper
elif [ "$provider" = github ]; then
    github_cred_helper
elif [ "$provider" = gitlab ]; then
    gitlab_cred_helper
elif [ "$provider" = bitbucket ]; then
    bitbucket_cred_helper
elif [ "$provider" = azure_devops ]; then
    azure_devops_cred_helper
else
    usage "unrecognized provider specified: $provider"
fi
