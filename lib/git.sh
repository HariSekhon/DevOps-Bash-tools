#!/usr/bin/env bash
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

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

. "$srcdir/utils.sh"

allbranches(){
    if which uniq_order_preserved.pl &>/dev/null; then
        local uniq=uniq_order_preserved.pl
    else
        local uniq="sort | uniq"
    fi
    # this only shows local branches, to show all remote ones do
    # git ls-remote | awk '/\/heads\//{print $2}' | sed 's,refs/heads/,,'
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
    local start_branch=$(git branch | grep ^\* | clean_branch_name);
    local branches="$(allbranches)";
    if [ "$start_branch" != "master" ]; then
        branches="$(sed "1,/$start_branch/d" <<< "$branches")";
    fi;
    local branch;
    for branch in $branches; do
        hr
        if [ -z "${FORCEMASTER:-}" -a "$branch" = "master" ]; then
            echo "skipping master branch for safety (set FORCEMASTER=1 environment variable to override)"
            continue
        fi
        if [ -n "${BRANCH_FILTER:-}" ] && ! egrep "$BRANCH_FILTER" <<< "$branch"; then
            continue
        fi
        echo "$branch:"
        if git branch | fgrep --color=auto -q "$branch"; then
            git checkout "$branch"
        else
            git checkout --track "origin/$branch";
        fi && eval $@ || return
        echo
    done
    git checkout "$start_branch"
}

mybranch(){
    git branch | awk '/^\*/ {print $2; exit}'
}

# shouldn't need to use this any more, git_check_branches_upstream.py from DevOps Python Tools repo has a --fix flag which will do this for all branches if they have no upstream set - https://github.com/harisekhon/devops-python-tools
set_upstream(){
    git branch --set-upstream-to origin/$(mybranch) $(mybranch)
}
