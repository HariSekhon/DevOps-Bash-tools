#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-08-07 00:27:46 +0300 (Wed, 07 Aug 2024)
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
. "$srcdir/lib/github.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Easily adds a git remote to a GitHub forked repo selected from a menu list

If executed from the checkout of GitHub repo, determines if this is a fork and if so finds the upstream forks to choose from

Or the owner/repo can be specified explicitly, with the shorthand '.' meaning the current repo's forks, regardless of whether it is itself a fork


Requires GitHub CLI to be installed and authenticated, as well as jq
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<owner/repo>]"

help_usage "$@"

max_args 1 "$@"

check_github_origin

if [ $# -gt 0 ]; then
    owner_repo="$1"
    shift
    if [ "$owner_repo" = . ]; then
        timestamp "Determining self owner/repo"
        owner_repo="$(github_owner_repo)"
        timestamp "Determined self owner/repo to be: $owner_repo"
    fi
elif is_github_fork; then
    timestamp "Detected running in the checkout of a forked repo"
    timestamp "Determining upstream origin repo"
    owner_repo="$(github_upstream_owner_repo || die "Not a forked repo?")"
    timestamp "Determined upstream origin repo to be: $owner_repo"
else
    timestamp "Determining owner/repo"
    owner_repo="$(github_owner_repo)"
    timestamp "Determined owner/repo to be: $owner_repo"
fi

timestamp "Retrieving forked repos for: $owner_repo"
fork_list="$(gh api "repos/$owner_repo/forks" --paginate --jq '.[].full_name')"

if is_blank "$fork_list"; then
    die "No forks found for repo: '$owner_repo"
fi

fork_owner_repo="$(fzf --prompt="Select a Fork: " --height=40% --border --ansi <<< "$fork_list")"

# default remote name
fork_remote="${fork_owner_repo//\//_}"

if is_blank "$fork_remote"; then
    die "Git remote name cannot be blank!"
fi

timestamp "Determining git base url"
echo
github_url_base="$(
    git remote -v |
    awk '/origin/ { print $2; exit }' |
    sed 's|\(.*github.com[:/]\).*|\1|'
)"

fork_remote_url="${github_url_base}${fork_owner_repo}"
fork_remote_url_escaped="${fork_remote_url//\//\\/}"

if git remote -v | awk '{print $2}' | grep -Eq "^$fork_remote_url(\\.git)?$"; then
    timestamp "Existing git remote found with fork url '$fork_remote_url', skipping adding remote"
    fork_remote="$(git remote -v | awk "/[[:space:]]${fork_remote_url_escaped}[[:space:].]/ {print \$1; exit}")"
    if is_blank "$fork_remote"; then
        die "Failed to parse existing git remote for url: $fork_remote_url_escaped"
    fi
    timestamp "Use existing fork remote: $fork_remote"
else
    fork_remote="$(dialog --inputbox "Enter name of git remote to create:" 8 40 "$fork_remote" 3>&1 1>&2 2>&3)"
    if git remote -v | grep -q "^${fork_remote}[[:space:]]"; then
        timestamp "Git remote '$fork_remote' already exists, not creating"
    else
        timestamp "Adding git remote '$fork_remote' to be able to pull directly from forked repo"
        git remote add "$fork_remote" "$fork_remote_url"
    fi
fi
echo

timestamp "Fetching repo '$fork_owner_repo' from git remote: $fork_remote"
git fetch "$fork_remote"
