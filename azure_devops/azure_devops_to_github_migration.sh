#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-09-10 14:10:20 +0100 (Fri, 10 Sep 2021)
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
. "$srcdir/lib/github.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Migrates Azure DevOps repos to GitHub

Idempotent - will find missing repos and migrate any missing ones across

If specifying a single repo, can optionally rename the destination repo on GitHub

Requirements:

- Azure DevOps and GitHub credentials in your environment variables - see these adjacent scripts for details:

    azure_devops_api.sh --help

    github_api.sh --help

  Azure DevOps organization/project and GitHub organization aren't case sensitive at the time of writing

- Your Git SSH credentials should be set up in both Azure DevOps and GitHub with permissions to clone from Azure and push to GitHub
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<azure_devops_organization> <azure_devops_project> <github_organization> [<repo>] [<new_repo_name>]"

help_usage "$@"

min_args 3 "$@"

azure_devops_organization="$1"
azure_devops_project="$2"
github_organization="$3"
azure_repo="${4:-}"
github_repo="${5:-}"

migrate_repo(){
    local azure_repo="$1"
    local github_repo="${2:-$azure_repo}"
    # mutate naming convention here if required as part of the migration
    #github_repo="${github_repo/old/new}"
    timestamp "migrating '$azure_repo' -> '$github_repo'"
    if ! "$srcdir/../github/github_api.sh" "/repos/$github_organization/$github_repo" &>/dev/null; then
        timestamp "creating github repo '$github_repo'"
        "$srcdir/../github/github_api.sh" "/orgs/$github_organization/repos" -X POST -d "{\"name\": \"$github_repo\", \"private\": true}" >/dev/null
    fi
    # API seems to not update the size field for ages, just do the clone anyway
    #if "$srcdir/../github/github_api.sh" "/repos/$github_organization/$github_repo" | jq -e '.size == 0' >/dev/null; then
    #    timestamp "repo is empty, cloning across"
        tmp="/tmp/azure_to_github_migration.$EUID" #.$$" - reuse the checkouts for now at the expense of potential race conditions
        mkdir -p "$tmp"
        pushd "$tmp" >/dev/null
        if ! [ -d "$azure_repo.git" ]; then
            git clone --mirror git@ssh.dev.azure.com:"v3/$azure_devops_organization/$azure_devops_project/$azure_repo"
        fi
        pushd "$azure_repo.git" >/dev/null
        if ! git remotes | awk '{print $1}' | sort -u | grep -q '^github$'; then
            timestamp "adding github remote"
            git remote add github git@github.com:"$github_organization/$github_repo.git"
        fi
        git fetch --all
        git push github --all
        # handles situation where github has added commits to the main branch - only handles the 'main' branch, would be more complicated to figure out which branches
        #if ! git push github --all; then
        #    git --work-tree="$PWD" checkout main
        #    git --work-tree="$PWD" pull github main
        #    git push github --all
        #fi
        git push github --tags
        popd >/dev/null
        popd >/dev/null
        timestamp "getting azure repo default branch"
        default_branch="$("$srcdir/azure_devops_api.sh" "/$azure_devops_organization/$azure_devops_project/_apis/git/repositories/$azure_repo" | jq -r '.defaultBranch' | sed 's/.*\///')"
        timestamp "setting github repo default branch to '$default_branch'"
        "$srcdir/../github/github_api.sh" "/repos/$github_organization/$github_repo" -X PATCH -d "{\"default_branch\": \"$default_branch\"}" >/dev/null
        timestamp "migrated '$azure_repo' -> '$github_repo'"
        echo >&2
    #fi
    echo >&2
}

if [ -n "$azure_repo" ]; then
    migrate_repo "$azure_repo" "$github_repo"
else
    timestamp "fetching list of Azure DevOps repos in organization '$azure_devops_organization' project '$azure_devops_project'"
    azure_devops_repos="$("$srcdir/azure_devops_api.sh" "/$azure_devops_organization/$azure_devops_project/_apis/git/repositories" | jq -r '.value[].name')"
    timestamp "fetching list of GitHub repos in organization '$github_organization'"
    #github_repos="$("$srcdir/../github/github_api.sh" "/orgs/$github_organization/repos" | jq -r '.[].name')"
    github_repos="$(get_github_repos "$github_organization" "is_organization")"

    # use GNU grep to avoid buggy Mac -f behaviour
    if is_mac; then
        grep(){
            ggrep "$@"
        }
    fi

    remaining_repos="$(grep -Fxvf <(echo "$github_repos") <<< "$azure_devops_repos")"

    # XXX: this will miss if there is any munging on repo naming and will go through the checks to create and populate the repo if empty
    echo "Azure DevOps repos missing on GitHub:"
    echo
    echo "$remaining_repos"
    echo
    for azure_repo in $remaining_repos; do
        migrate_repo "$azure_repo"
    done
fi
