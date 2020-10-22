#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2017-11-21 10:45:41 +0100 (Tue, 21 Nov 2017)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Export of useful Git utility functions from years gone by
#
# far more git functions are available in the interactive library .bash.d/git.sh

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir_git="${srcdir:-}"
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/utils.sh"

git_repo(){
    git remote -v 2>/dev/null |
    awk '{print $2}' |
    head -n1 |
    sed '
        s,.*://,,;
        s/.*@//;
        s/[^:/]*[:/]//;
        s/\.git$//;
    '
}

git_repo_name(){
    git_repo |
    sed 's|.*/||'
}

git_root(){
    git rev-parse --show-toplevel
}

allbranches(){
    if type -P uniq_order_preserved.pl &>/dev/null; then
        local uniq=uniq_order_preserved.pl
    else
        local uniq="sort | uniq"
    fi
    # this only shows local branches, to show all remote ones do
    # git ls-remote | awk '/\/heads\//{print $2}' | sed 's,refs/heads/,,'
    # shellcheck disable=SC2086
    git branch -a | clean_branch_name | eval $uniq
}

clean_branch_name(){
    sed '
        s/^\* // ;
        s/.*\/// ;
        s/^[[:space:]]*// ;
        s/[[:space:]]*$// ;
        s/.*[[:space:]]// ;
        s/)[[:space:]]*//
    '
}

foreachbranch(){
    local start_branch
    start_branch=$(git branch | grep '^\*' | clean_branch_name);
    local branches
    branches="$(allbranches)";
    if [ "$start_branch" != "master" ]; then
        branches="$(sed "1,/$start_branch/d" <<< "$branches")";
    fi;
    local branch;
    for branch in $branches; do
        hr
        if [ -z "${FORCEMASTER:-}" ] && [ "$branch" = "master" ]; then
            echo "skipping master branch for safety (set FORCEMASTER=1 environment variable to override)"
            continue
        fi
        if [ -n "${BRANCH_FILTER:-}" ] && ! grep -E "$BRANCH_FILTER" <<< "$branch"; then
            continue
        fi
        echo "$branch:"
        if git branch | grep -Fq --color=auto "$branch"; then
            git checkout "$branch"
        else
            git checkout --track "origin/$branch";
        fi &&
        eval "$@" || return
        echo
    done
    git checkout "$start_branch"
}

mybranch(){
    git branch | awk '/^\*/ {print $2; exit}'
}

# shouldn't need to use this any more, git_check_branches_upstream.py from DevOps Python Tools repo has a --fix flag which will do this for all branches if they have no upstream set - https://github.com/harisekhon/devops-python-tools
set_upstream(){
    git branch --set-upstream-to "origin/$(mybranch)" "$(mybranch)"
}

# load domain, user and token variables from environment
# don't export variables, they are used as globals in calling script but shouldn't be visible to child processes
# shellcheck disable=SC2034
git_provider_env(){
    local name="$1"
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
        token="${AZURE_DEVOPS_TOKEN:-${AZURE_DEVOPS_PASSWORD:-}}"
    fi
}

# Azure DevOps has non-uniform URLs compared to the 3 main Git repos so here are general conversion rules used by git_remotes_add_public_repos.sh / git_remotes_set_multi_origin.sh
git_to_azure_url(){
    local url="$1"
    # XXX: you should set $AZURE_DEVOPS_PROJECT in your environment or call your project GitHub as I have - there is no portable way to infer this from other repos since they don't have this hierarchy level - querying the API might work if there is only a single project, but this might get overly complicated if requiring additional authentication
    project="${AZURE_DEVOPS_PROJECT:-}"
    if [ -z "$project" ]; then
        timestamp "WARNING: \$AZURE_DEVOPS_PROJECT not set, defaulting to project name 'GitHub'"
        project="GitHub"
    fi
    url="${url/git@dev.azure.com/git@ssh.dev.azure.com}"
    if [[ "$url" =~ ssh.dev.azure.com ]]; then
        url="${url/:/:v3\/}"
        # XXX: lowercase username and inject $project just before the repo name to conform to weird Azure DevOps urls
        url="$(perl -pe "s/(\\/[^\\/]+)(\\/[^\\/]+)$/\\L\$1\\E\\/$project\$2/" <<< "$url")"
    else # https
        url="$(perl -pe "s/(\\/[^\\/]+)(\\/[^\\/]+)$/\\L\$1\\E\\/$project\\/_git\$2/" <<< "$url")"
    fi
    echo "$url"
}

azure_to_git_url(){
    local url="$1"
    url="${url/:v3\//:}"
    url="${url/\/_git\//\/}"
    # XXX: strip the middle component out from git@ssh.dev.azure.com:v3/harisekhon/GitHub/DevOps-Bash-tools
    url="$(perl -pe 's/([\/:][^\/:]+)(\/[^\/]+)(\/[^\/]+)$/$1$3/' <<< "$url")"
    echo "$url"
}

srcdir="$srcdir_git"
