#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-03-22 10:47:11 +0000 (Tue, 22 Mar 2022)
#
#  https://github.com/HariSekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
# gets absolute rather than relative path, for when we pushd later, otherwise relative $srcdir references will break
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/github.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Mirrors all or given repos from GitHub to BitBucket via APIs and HTTPS mirror clones

Useful to create/sync GitHub repos to BitBucket for migration or to cron for fast free DR purposes. Includes repo descriptions but not PRs/Wikis/Releases

Especially in dynamic environments where people are adding new repos, avoids having to maintain configurations as finds and iterates all non-fork repos by default
Can't use Terraform to dynamically create these backups because a simple commented/deleted code mistake would bypass prevent_destroy and delete your backup repos as well as your originals!

    https://github.com/hashicorp/terraform/issues/17599

Cron this script as per your preferred backup schedule

If no repos are given, iterates all non-fork repos for the current user or GitHub organization

Each repo will have the same name in BitBucket as it does on GitHub
BitBucket workspace is assumed to be the same as the BitBucket user name (set \$BITBUCKET_WORKSPACE to override)

Requires \$GITHUB_TOKEN AND \$BITBUCKET_TOKEN to be set

In a GitHub Organization, only repos the user can read will be mirrored, others won't be returned in the list of GitHub repos to even try (as an outside collaborator user)

Source GitHub and Destination BitBucket accounts, in order or priority:

    \$GITHUB_ORGANIZATION, \$GITHUB_USER or owner of the \$GITHUB_TOKEN
    \$BITBUCKET_OWNER, \$BITBUCKET_USER or the owner of the \$BITBUCKET_TOKEN
    \$BITBUCKET_WORKSPACE - the container where the repositories are created, can auto-determine if there is only one workspace owned by the \$BITBUCKET_USER

If \$CLEAR_CACHE_GITHUB_MIRROR is set to any value, deletes the /tmp cache and uses a fresh clone mirror. This can sometimes clear push errors.
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<repo1> <repo2> <repo3> ...]"

check_env_defined "GITHUB_TOKEN"
check_env_defined "BITBUCKET_TOKEN"
#check_env_defined "BITBUCKET_WORKSPACE"

help_usage "$@"

#min_args 1 "$@"

timestamp "Starting GitHub to BitBucket mirroring"
echo >&2

user="${GITHUB_USER:-$(get_github_user)}"
owner="${GITHUB_ORGANIZATION:-$user}"
bitbucket_owner="${BITBUCKET_OWNER:-${BITBUCKET_USER:-$("$srcdir/bitbucket_api.sh" /user | jq -r .username)}}"
bitbucket_workspace="${BITBUCKET_WORKSPACE:-}"

if is_blank "$owner"; then
    die "Failed to determine GitHub owner"
fi
if is_blank "$bitbucket_owner"; then
    die "Failed to determine BitBucket owner"
fi

if is_blank "$bitbucket_workspace"; then
    timestamp "Attempting to auto-determine BitBucket workspace from user if only one exists"
    bitbucket_workspace="$("$srcdir/bitbucket_api.sh" '/user/permissions/workspaces?q=permission="owner"' | jq -r '.values[].workspace.slug')"
    if is_blank "$bitbucket_workspace"; then
        die "Failed to determine BitBucket workspace"
    fi
    timestamp "Determined BitBucket workspace to be '$bitbucket_workspace'"
    echo >&2
fi

if [ $# -gt 0 ]; then
    repos="$*"
else
    timestamp "Getting list of all non-fork GitHub repos owned by '$owner'"
    repos="$(get_github_repos "$owner" "${GITHUB_ORGANIZATION:-}")"
    echo >&2
fi

# not using mktemp because we want to reuse this staging area between runs for efficiency
tmpdir="/tmp/github_to_bitbucket_mirroring/$owner"

if [ -n "${CLEAR_CACHE_GITHUB_MIRROR:-}" ]; then
    timestamp "Removing cache: $tmpdir"
    rm -fr "$tmpdir"
fi

timestamp "Switching to '$tmpdir' directory for mirror staging"
mkdir -p -v "$tmpdir"
cd "$tmpdir"
echo >&2

succeeded=0
failed=0

mirror_repo(){
    local repo="$1"
    # BitBucket doesn't allow repo name like .github, only alnum, dashes and underscores, and not starting with unusual characters either
    bitbucket_repo="$repo"
    bitbucket_owner_repo="$bitbucket_owner/$bitbucket_repo"

    timestamp "Checking BitBucket repo '$bitbucket_owner/$bitbucket_repo' exists"
    if ! "$srcdir/bitbucket_api.sh" "/repositories/$bitbucket_owner_repo" >/dev/null; then
        timestamp "Creating BitBucket repo '$bitbucket_owner/$bitbucket_repo'"
        "$srcdir/bitbucket_api.sh" "/repositories/$bitbucket_owner_repo" -X POST -d "{ \"scm\": \"git\", \"key\": \"$bitbucket_workspace\" }" >/dev/null || return 1
        echo >&2
    fi

    timestamp "Checking GitHub repo for description to copy"
    "$srcdir/github_repo_description.sh" "$owner/$repo" |
    sed "s/^$repo/$bitbucket_repo/" |
    # timestamp not needed here as bitbucket_project_set_description.sh will output if it is setting the repo description
    "$srcdir/bitbucket_repo_set_description.sh"

    if [ -d "$repo.git" ]; then
        timestamp "Using existing clone in directory '$repo.git'"
        pushd "$repo.git" >/dev/null || return 1
        git remote update origin || return 1
    else
        timestamp "Cloning GitHub repo to directory '$repo.git'"
        git clone --mirror "https://$user:$GITHUB_TOKEN@github.com/$owner/$repo.git" || return 1
        pushd "$repo.git" >/dev/null || return 1
    fi

    if ! git remote -v | awk '{print $1}' | grep -Fxq bitbucket; then
        timestamp "Adding BitBucket remote origin"
        git remote add bitbucket "https://$bitbucket_owner:$BITBUCKET_TOKEN@bitbucket.org/$bitbucket_owner/$bitbucket_repo.git"
    fi

    timestamp "Pushing all branches to BitBucket"
    git push --all bitbucket || return 1  # XXX: without return 1 the function ignores errors, even with set -e inside the function

    timestamp "Pushing all tags to BitBucket"
    git push --tags bitbucket || return 1

    # more dangerous, force overwrites remote repo refs
    #git push --mirror bitbucket || return 1

    popd >/dev/null || return 1
    echo >&2
    ((succeeded+=1))
}

failed_repos=""

for repo in $repos; do
    if [[ "$repo" =~ / ]]; then
        die "Repo '$repo' should be specified without owner prefix"
    fi
    if ! mirror_repo "$repo"; then
        echo >&2
        timestamp "ERROR: Failed to mirror repo '$repo' to BitBucket" >&2
        failed_repos+=" $repo"
        echo >&2
        ((failed+=1))
    fi
done

if [ $failed -gt 0 ]; then
    timestamp "ERROR: $failed GitHub repos failed to mirror to BitBucket ($succeeded succeeded). Failed repos: $failed_repos"
    exit 1
fi

timestamp "GitHub to BitBucket mirroring completed successfully for $succeeded repos"
