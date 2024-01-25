#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-03-31 11:06:02 +0100 (Thu, 31 Mar 2022)
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
Mirrors all or given repos from GitHub to GCP Source Repos via GCloud SDK and Git HTTPS mirror clones

Useful to create/sync GitHub repos to GCP Source Repos for migration or to cron for fast almost free DR purposes
(almost \$0 GCP charges compared to \$100-\$400+ per month for Rewind / BackHub)

Includes all branches and tags, but not description/PRs/Wikis/Releases

Especially useful to backup dynamic environments where people are adding new repos all the time, avoids having to maintain configurations as finds and iterates all non-fork repos by default
Can't use Terraform to dynamically create these backups because a simple commented/deleted code mistake would bypass prevent_destroy and delete your backup repos as well as your originals!

    https://github.com/hashicorp/terraform/issues/17599

Cron this script as per your preferred backup schedule

Unfortunately GCloud SDK doesn't currently support configuring GCP's GitHub automatic mirroring, which is only available through the UI Console, making it unsuitable for automation
Cloud Source Repos are extremely rudimentary with no features and only really suitable for mirror trigger repos or as backups, and can't even configure a different default branch

If no repos are given, iterates all non-fork repos for the current user or GitHub organization

Each repo will have the same name in GCP Source Repos to avoid clashing with manually configured GCP automatically mirroring functionality which creates repos in the format 'github_{owner}_{repo}'
Any non-letter leading characters and non alphanumeric/dots/dashs/underscores will be removed to meet GCP Source Repos naming conventions eg. '.github' -> 'github' repo

For source GitHub accounts, requires:

    - \$GITHUB_TOKEN
    - \$GITHUB_ORGANIZATION, \$GITHUB_USER or else infers owner of the \$GITHUB_TOKEN

For GCP Source Repos requires:

    - \$CLOUDSDK_CORE_PROJECT
    - GCloud SDK installed and authenticated

In a GitHub Organization, only repos the user can read will be mirrored, others won't be returned in the list of GitHub repos to even try (as an outside collaborator user)


If \$CLEAR_CACHE=true, deletes the /tmp cache and uses a fresh clone mirror. This can sometimes clear push errors.

If \$FORCE_MIRROR=true, runs a mirror operation (overwrites refs and deletes removed branches). Not the default for safety.
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<repo1> <repo2> <repo3> ...]"

check_env_defined "GITHUB_TOKEN"
check_env_defined "CLOUDSDK_CORE_PROJECT"

help_usage "$@"

#min_args 1 "$@"

timestamp "Starting GitHub to GCP Source Repos mirroring"
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
tmpdir="/tmp/github_mirror_to_gcp_source_repos/$owner"

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

account="$(gcloud config list --format='get(core.account)')"

mirror_repo(){
    local repo="$1"
    #local description
    # XXX: same naming convention of GCP's GitHub mirroring so the two mechanisms can interoperate
    #      must be lowercase because GSR is case sensitive and mirroring will create a separate repo otherwise
    #local gcp_repo="github_${owner}_$repo"
    #local gcp_repo="$(tr '[:upper:]' '[:lower:]' <<< "$gcp_repo")"
    local gcp_repo="$repo"
    gcp_repo="$(sed 's/^[^[:alpha:]]*//; s/[^[:alnum:]._-]//' <<< "$gcp_repo")"

    timestamp "Checking GCP repo '$gcp_repo' exists"
    if ! gcloud source repos list --format='value(name)' | grep -Fxq "$gcp_repo" >/dev/null; then
        timestamp "Creating GCP source repo '$gcp_repo'"
        gcloud source repos create "$gcp_repo" || return 1
        echo >&2
    fi

    # XXX: GCP Source Repos don't support descriptions yet
    #timestamp "Checking GitHub repo for description to copy"
    #description="$("$srcdir/github_repo_description.sh" "$owner/$repo" | sed "s/^${repo}[[:space:]]*//")"
    #if [ -n "$description" ]; then
    #    timestamp "Setting GCP repo '$gcp_repo' description to '$description'"
    #    # gcloud source repos update --description ... no such command yet
    #fi

    if [ -d "$repo.git" ]; then
        timestamp "Using existing clone in directory '$repo.git'"
        pushd "$repo.git" >/dev/null || return 1
        git remote update origin || return 1
    else
        timestamp "Cloning GitHub repo to directory '$repo.git'"
        git clone --mirror "https://$user:$GITHUB_TOKEN@github.com/$owner/$repo.git" || return 1
        pushd "$repo.git" >/dev/null || return 1
    fi

    if ! git remote -v | awk '{print $1}' | grep -Fxq gcp; then
        timestamp "Adding GCP remote origin"
        git remote add gcp "https://source.developers.google.com/p/$CLOUDSDK_CORE_PROJECT/r/$gcp_repo"
        # having a blank helper before the real help prevents:
        # bad input: ..........
        git config --replace-all credential.https://source.developers.google.com/.helper ''
        git config --add         credential.https://source.developers.google.com/.helper "!gcloud auth git-helper --account=$account --ignore-unknown \$@"
    fi

    if [ "${FORCE_MIRROR:-}" = true ]; then
        # more dangerous, force overwrites remote repo refs
        timestamp "Force mirroring to GCP Source Repo (overwrite)"
        git push --mirror gcp || return 1
    else
        timestamp "Pushing all branches to GCP Source Repo"
        git push --all gcp || return 1  # XXX: without return 1 the function ignores errors, even with set -e inside the function

        timestamp "Pushing all tags to GCP Source Repo"
        git push --tags gcp || return 1
    fi

    # TODO: if GCP Source Repos supports protected branches in future
    #timestamp "Enabling branch protections on GCP mirror repo '$gcp_repo'"
    #"$srcdir/gcp_source_repo_protect_branches.sh" "$gcp_repo"

    # XXX: GCloud SDK is too rudimentary, doesn't support setting default branch
    #timestamp "Getting GitHub repo '$repo' default branch"
    #local default_branch
    #default_branch="$("$srcdir/github_api.sh" "/repos/$owner/$repo" | jq -r '.default_branch')"
    #timestamp "Setting GCP Source Repo '$gcp_repo' default branch to '$default_branch'"
    # # gcloud source repos update  ... so default branch switch

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
            timestamp "ERROR: Failed to mirror repo '$repo' to GCP"
            failed_repos+=" $repo"
            echo >&2
            ((failed+=1))
        fi
    fi
done

if [ $failed -gt 0 ]; then
    timestamp "ERROR: $failed GitHub repos failed to mirror to GCP ($succeeded succeeded). Failed repos: $failed_repos"
    exit 1
fi

timestamp "GitHub to GCP mirroring completed successfully for $succeeded repos"
