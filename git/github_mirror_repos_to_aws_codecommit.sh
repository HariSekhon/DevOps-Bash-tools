#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-03-29 19:19:43 +0100 (Tue, 29 Mar 2022)
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
# gets absolute rather than relative path, for when we pushd later, otherwise relative $srcdir references will break
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/github.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Mirrors all or given repos from GitHub to AWS CodeCommit via AWS CLI and Git HTTPS mirror clones

Useful to create/sync GitHub repos to AWS CodeCommit for migration or to cron for fast almost free DR purposes
(almost \$0 AWS charges compared to \$100-\$400+ per month for Rewind / BackHub)

Includes repo descriptions and all branches and tags, but not PRs/Wikis/Releases

Especially useful to backup dynamic environments where people are adding new repos all the time, avoids having to maintain configurations as finds and iterates all non-fork repos by default
Can't use Terraform to dynamically create these backups because a simple commented/deleted code mistake would bypass prevent_destroy and delete your backup repos as well as your originals!

    https://github.com/hashicorp/terraform/issues/17599

Cron this script as per your preferred backup schedule

If no repos are given, iterates all non-fork repos for the current user or GitHub organization

Each repo will have the same name in AWS as it does on GitHub

For source GitHub accounts, requires:

    - \$GITHUB_TOKEN
    - \$GITHUB_ORGANIZATION, \$GITHUB_USER or else infers owner of the \$GITHUB_TOKEN

For AWS CodeCommit requires:

    - \$AWS_DEFAULT_REGION
    - AWS Credentials:
      - AWS CLI configured with CodeCommit full access to create repositories (\$AWS_PROFILE, \$AWS_ACCESS_KEY_ID, \$AWS_SECRET_ACCESS_KEY etc.)
      - \$AWS_GIT_USER and \$AWS_GIT_PASSWORD
          or
      - Python Pip git-remote-codecommit module to be installed to use AWS CLI credentials

In a GitHub Organization, only repos the user can read will be mirrored, others won't be returned in the list of GitHub repos to even try (as an outside collaborator user)


If \$CLEAR_CACHE=true, deletes the /tmp cache and uses a fresh clone mirror. This can sometimes clear push errors.

If \$FORCE_MIRROR=true, runs a mirror operation (overwrites refs and deletes removed branches). Not the default for safety.
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<repo1> <repo2> <repo3> ...]"

check_env_defined "GITHUB_TOKEN"
check_env_defined "AWS_DEFAULT_REGION"

help_usage "$@"

#min_args 1 "$@"

timestamp "Starting GitHub to AWS CodeCommit mirroring"
echo >&2

user="${GITHUB_USER:-$(get_github_user)}"
owner="${GITHUB_ORGANIZATION:-$user}"

if is_blank "$owner"; then
    die "Failed to determine GitHub owner"
fi

if [ $# -gt 0 ]; then
    repos="$*"
else
    timestamp "Getting list of all non-fork GitHub repos owned by '$owner'"
    repos="$(get_github_repos "$owner" "${GITHUB_ORGANIZATION:-}")"
    echo >&2
fi

# not using mktemp because we want to reuse this staging area between runs for efficiency
tmpdir="/tmp/github_mirror_to_aws_codecommmit/$owner"

if [ "${CLEAR_CACHE:-}" = true ]; then
    timestamp "Removing cache: $tmpdir"
    rm -fr -- "$tmpdir"
fi

timestamp "Switching to '$tmpdir' directory for mirror staging"
mkdir -p -v "$tmpdir"
cd "$tmpdir"
echo >&2

succeeded=0
failed=0

mirror_repo(){
    local repo="$1"
    local description
    # in case we need to mutate the names later, such as working around dots in repo names eg. ".github"
    local aws_repo="$repo"

    timestamp "Checking AWS repo '$aws_repo' exists"
    if ! aws codecommit list-repositories | jq -r '.repositories[].repositoryName' | grep -Fxq "$aws_repo" >/dev/null; then
        timestamp "Creating AWS repo '$aws_repo'"
        aws codecommit create-repository --repository-name "$aws_repo" || return 1
        echo >&2
    fi

    timestamp "Checking GitHub repo for description to copy"
    description="$("$srcdir/github_repo_description.sh" "$owner/$repo" | sed "s/^${repo}[[:space:]]*//")"
    if [ -n "$description" ]; then
        timestamp "Setting AWS repo '$aws_repo' description to '$description'"
        aws codecommit update-repository-description --repository-name "$aws_repo" --repository-description "$description"
    fi

    if [ -d "$repo.git" ]; then
        timestamp "Using existing clone in directory '$repo.git'"
        pushd "$repo.git" >/dev/null || return 1
        git remote update origin || return 1
    else
        timestamp "Cloning GitHub repo to directory '$repo.git'"
        git clone --mirror "https://$user:$GITHUB_TOKEN@github.com/$owner/$repo.git" || return 1
        pushd "$repo.git" >/dev/null || return 1
    fi

    if ! git remote -v | awk '{print $1}' | grep -Fxq aws; then
        timestamp "Adding AWS remote origin"
        if [ -n "${AWS_GIT_USER:-}" ] &&
           [ -n "${AWS_GIT_PASSWORD:-}" ]; then
            timestamp "Using AWS git user and url encoded password"
            AWS_GIT_PASSWORD_URLENCODED="$("$srcdir/../bin/urlencode.sh" <<< "$AWS_GIT_PASSWORD")"
            git remote add aws "https://$AWS_GIT_USER:$AWS_GIT_PASSWORD_URLENCODED@git-codecommit.$AWS_DEFAULT_REGION.amazonaws.com/v1/repos/$repo"
        else
            timestamp "Using AWS credentials via git-remote-codecommit"
            git remote add aws "codecommit::$AWS_DEFAULT_REGION://$repo"
        fi
    fi

    if [ "${FORCE_MIRROR:-}" = true ]; then
        # more dangerous, force overwrites remote repo refs
        timestamp "Force mirroring to AWS CodeCommit (overwrite)"
        git push --mirror aws || return 1
    else
        timestamp "Pushing all branches to AWS CodeCommit"
        git push --all aws || return 1  # XXX: without return 1 the function ignores errors, even with set -e inside the function

        timestamp "Pushing all tags to AWS CodeCommit"
        git push --tags aws || return 1
    fi

    # TODO: if AWS CodeCommit supports protected branches in future
    #timestamp "Enabling branch protections on AWS mirror repo '$aws_repo'"
    #"$srcdir/aws_codecommit_protect_branches.sh" "$aws_repo"

    timestamp "Getting GitHub repo '$repo' default branch"
    local default_branch
    default_branch="$("$srcdir/github_api.sh" "/repos/$owner/$repo" | jq -r '.default_branch')"
    timestamp "Setting AWS CodeCommit repo '$aws_repo' default branch to '$default_branch'"
    aws codecommit update-default-branch --repository-name "$aws_repo" --default-branch-name "$default_branch"

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
        popd >/dev/null || :
        timestamp "Mirroring failed, clearing cache and trying again"
        rm -fr -- "$tmpdir/$repo.git"
        if ! mirror_repo "$repo"; then
            echo >&2
            timestamp "ERROR: Failed to mirror repo '$repo' to AWS"
            failed_repos+=" $repo"
            echo >&2
            ((failed+=1))
        fi
    fi
done

if [ $failed -gt 0 ]; then
    timestamp "ERROR: $failed GitHub repos failed to mirror to AWS ($succeeded succeeded). Failed repos: $failed_repos"
    exit 1
fi

timestamp "GitHub to AWS mirroring completed successfully for $succeeded repos"
