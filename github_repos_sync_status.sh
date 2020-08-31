#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-31 18:05:24 +0100 (Mon, 31 Aug 2020)
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

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC1090
. "$srcdir/lib/github.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
For each non-fork GitHub repo, checks corresponding GitLab and/or BitBucket repos to check they are in sync with the same master hashref

Useful for checking if GitLab repo mirroring has broken or if BitBucket hasn't been pushed to be kept in sync with master GitHub repos


Output Format:

Repo: <user>/<repo>    GitHub: <sha_hash>        GitLab: <sha_hash>        BitBucket: <sha_hash>             In-Sync: <boolean>

Output Format If selecting only one of --gitlab / --bitbucket:

Repo: <user>/<repo>    GitHub: <sha_hash>        GitLab: <sha_hash>        In-Sync: <boolean>

Repo: <user>/<repo>    GitHub: <sha_hash>        BitBucket: <sha_hash>     In-Sync: <boolean>


Arguments can be specified to check only select repos, and options can be specified to compare each GitHub repo to its
GitLab or BitBucket counterpart of the same name (by default checks both)

By default this will check through all GitHub repos - this can be pages of hundreds of lines of GitHub repos, so for
efficiency you may want to explicitly specify the repos as args or in cases where not all repos are mirrored to GitLab
or pushed to BitBucket

User name is assumed to be the same across GitHub / GitLab / BitBucket. If it's not, make sure to specify \$GITLAB_USER / \$BITBUCKET_USER to override
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[options] [<repos_to_check>]"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_switches="
-g --gitlab         Compare each GitHub repo with its GitLab counterpart
-b --bitbucket      Compare each GitHub repo with its BitBucket counterpart
"

help_usage "$@"

#min_args 1 "$@"

repos=()
check_gitlab=0
check_bitbucket=0

for arg; do
    case "$arg" in
        -g|--gitlab)    check_gitlab=1
                        ;;
     -b|--bitbucket)    check_bitbucket=1
                        ;;
         -D|--debug)    export DEBUG=1
                        shift || :
                        ;;
                 -*)    usage
                        ;;
                  *)    repos+=("$arg")
                        ;;
    esac
done

github_user="$(get_github_user)"

check_repos(){
    for repo in "${@:-$(get_github_repos "$github_user")}"; do
        github_master_hashref="$("$srcdir/github_api.sh" "/repos/$github_user/$repo/git/ref/heads/master" | jq -r '.object.sha')"
        # don't printf as we go because it's harder to debug, instead collect the line and print in one go
        line="$(printf 'Repo: %s\tGitHub: %s\t' "$github_user/$repo" "$github_master_hashref")"
        in_sync=True
        if [ $check_gitlab = 1 ] || [ $check_bitbucket = 0 ]; then
            gitlab_master_hashref="$("$srcdir/gitlab_api.sh" "/projects/<user>%2F$repo/repository/branches/master" 2>/dev/null | jq -r '.commit.id' || echo None)"
            line+="$(printf 'GitLab: %s\t' "$gitlab_master_hashref")"
            if [ "$gitlab_master_hashref" != "$github_master_hashref" ]; then
                in_sync=False
            fi
        fi
        if [ $check_bitbucket = 1 ] || [ $check_gitlab = 0 ]; then
            bitbucket_master_hashref="$("$srcdir/bitbucket_api.sh" "/repositories/<user>/$repo/refs/branches/master" 2>/dev/null | jq -r '.target.hash' || echo None)"
            line+="$(printf 'BitBucket: %s\t' "$bitbucket_master_hashref")"
            if [ "$bitbucket_master_hashref" != "$github_master_hashref" ]; then
                in_sync=False
            fi
        fi
        printf '%s\tIn-Sync: %s\n' "$line" "$in_sync"
    done
}

if [ "${#repos[@]}" -gt 0 ]; then
    check_repos "${repos[@]}"
else
    # want splitting
    # shellcheck disable=SC2046
    check_repos $(get_github_repos "$github_user")
fi
