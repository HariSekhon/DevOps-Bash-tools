#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-08-16 22:08:31 +0200 (Fri, 16 Aug 2024)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
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
Runs pre-commit on all files changed on the current branch vs the default branch

Useful to reproduce pre-commit checks that are failing in pull requests to get your PRs to pass

Requires git and pre-commit to be installed and must be run on the feature branch in the git repo checkout
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

num_args 0 "$@"

git_root="$(git_root)"

echo "cd $git_root"
cd "$git_root"

default_branch="$(git symbolic-ref refs/remotes/origin/HEAD | sed 's|.*/||')"

changed_files=()
while IFS= read -r filename; do
    changed_files+=("$filename")
done < <(git diff --name-only "$default_branch"..)

echo
echo "pre-commit run --files ${changed_files[*]}"
echo
pre-commit run --files "${changed_files[@]}"
