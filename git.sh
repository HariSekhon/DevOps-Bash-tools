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
    eval git branch -a | clean_branch_name | $uniq
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
