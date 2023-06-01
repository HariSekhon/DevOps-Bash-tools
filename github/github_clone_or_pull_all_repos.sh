#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2023-06-01 00:55:07 +0100 (Thu, 01 Jun 2023)
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
Git clones all repos for a given owner (user or organization)

Clones repos to the current directory using the same directory names as each repo

By default will clone via SSH. Set the environment variable GIT_HTTPS to any value to use the HTTPS protocol to clone instead

If the directory already exists, enters, switches to the default branch and does a 'git pull'

For an organization, you must set the environment variable \$GITHUB_ORGANIZATION, otherwise by default will attempt to determine your github user via \$GITHUB_USER or your currently authenticated GitHub API user as defined from the utility script github_api.sh

Requires Git and the adjacent github_api.sh script to be installed and configured for authentication
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

max_args 1 "$@"

owner="${GITHUB_ORGANIZATION:-${GITHUB_USER:-$(get_github_user)}}"

github_url="git@github.com:"
if [ -n "${GIT_HTTPS:-}" ]; then
    github_url="https://github.com/"
fi

trap_cmd 'echo Exited with error'

get_github_repos "$owner" "${GITHUB_ORGANIZATION:-}" |
while read -r repo; do
    if [ -d "$repo" ]; then
        timestamp "GitHub repo directory '$repo' already exists, entering directory to update checkout"
        pushd "$repo" >/dev/null
        echo
        branch="$(default_branch)"
        timestamp "Switching to default branch '$branch'"
        if git status --porcelain | grep -q '^.M'; then
            echo
            timestamp "Stashing changes in progress"
            git stash
            echo
        fi
        git checkout "$branch"
        echo
        timestamp "Git Pull"
        git pull
        if git stash list | grep -q .; then
            timestamp "Popping stash"
            git stash pop 2>/dev/null || :
            echo
        fi
        echo
        timestamp "Leaving directory"
        popd >/dev/null
    else
        timestamp "Cloning repo '$owner/$repo' to directory '$repo'"
        git clone "$github_url""$owner/$repo"
    fi
    echo
    hr
    echo
done
untrap
timestamp "All github repos cloned and up to date for owner '$owner'"
