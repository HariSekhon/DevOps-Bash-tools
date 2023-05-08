#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-07-14 16:57:44 +0100 (Thu, 14 Jul 2022)
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
. "$srcdir/lib/git.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Runs kustomize build in the current vs the target base Git branch, for all directories given as args

Useful to validate kustomization.yaml refactoring, such as changing bases, switching to tagged external bases and wanting to ensure the refactor is a no-op

If no directories are given, assumes to kustomize build in the local directory


Requires Kustomize 4.x for --enable-helm support
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<git_branch> [<dir1> <dir2> <dir3> ...]"

help_usage "$@"

min_args 1 "$@"

original_branch="$(current_branch)"
base_branch="$1"
shift || :

dirs=("$@")
if [ -z "${dirs[*]:-}" ]; then
    dirs+=("$PWD")
fi

trap_cmd "popd &>/dev/null; git checkout '$original_branch' &>/dev/null; git stash pop &>/dev/null || :"

timestamp "Collecting kustomize build outputs for directories in current branch '$original_branch': $*"
echo
for dir in "${dirs[@]}"; do
    mkdir -p "/tmp/$dir.$$"
    pushd "$dir"
    kustomize build --enable-helm > "/tmp/$dir.$$/head"
    popd
done
echo

timestamp "Stashing any uncommitted changes in current branch that might prevent a branch switch"
echo
git stash
echo

timestamp "Switching to base branch: $base_branch"
git checkout --quiet "$base_branch"
echo

timestamp "Collecting kustomize build outputs for directories in base branch '$base_branch': $*"
echo
for dir in "${dirs[@]}"; do
    pushd "$dir"
    kustomize build --enable-helm > "/tmp/$dir.$$/base"
    popd
done
echo

timestamp "Switching back to original branch: $original_branch"
git checkout --quiet "$original_branch"
echo

timestamp "Restoring any stashed changes"
echo
git stash pop || :
echo

timestamp "Differences per directory from base branch '$base_branch' to head current branch '$original_branch':"
echo
for dir in "${dirs[@]}"; do
    echo "Directory: $dir"
    echo
    diff "/tmp/$dir.$$/base" "/tmp/$dir.$$/head" || :
    echo
    echo
done

untrap
