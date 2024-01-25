#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-31 18:05:24 +0100 (Mon, 31 Aug 2020)
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
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/github.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
For each non-fork GitHub repo, checks corresponding GitLab / BitBucket / Azure DevOps repos to check they are in sync with the same master hashref

Useful for checking if GitLab repo mirroring has broken or if BitBucket / Azure DevOps haven't been pushed to be kept in sync with master GitHub repos


Output Format:

Repo: <user>/<repo>    GitHub: <sha_hash>        GitLab: <sha_hash>        BitBucket: <sha_hash>        Azure_Devops: <sha_hash>        In-Sync: <boolean>

Output Format If selecting only one of --gitlab / --bitbucket / --azure-devops:

Repo: <user>/<repo>    GitHub: <sha_hash>        GitLab: <sha_hash>        In-Sync: <boolean>

Repo: <user>/<repo>    GitHub: <sha_hash>        BitBucket: <sha_hash>     In-Sync: <boolean>

Repo: <user>/<repo>    GitHub: <sha_hash>        Azure_DevOps: <sha_hash>  In-Sync: <boolean>


Arguments can be specified to check only select repos, and options can be specified to compare each GitHub repo to its
GitLab or BitBucket counterpart of the same name (by default checks both)

By default this will check through all GitHub repos - this can be pages of hundreds of lines of GitHub repos, so for
efficiency you may want to explicitly specify the repos as args or in cases where not all repos are mirrored to GitLab
or pushed to BitBucket

User name is assumed to be the same across GitHub / GitLab / BitBucket. If it's not, make sure to specify \$GITLAB_USER / \$BITBUCKET_USER to override

Caveats:

- due to a limitation of the BitBucket API requiring username + token, cannot auto-determine username so if your
\$BITBUCKET_USERNAME / \$BITBUCKET_USER / \$USER etc is incorrect, this'll fail to authenticate and won't find the relevant repo,
returning 'None' for the hashref and 'In-Sync: False'. You must ensure your BitBucket username is correct

- the BitBucket workspace is assumed to be the same as the username
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[options] [<repos_to_check>]"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_switches="
-g --gitlab         Compare each GitHub repo with its GitLab counterpart
-b --bitbucket      Compare each GitHub repo with its BitBucket counterpart
-a --azure-devops   Compare each GitHub repo with its Azure DevOps counterpart
-d --date           Compare by date of latest commit instead of hashref
-l --long-hashrefs  Use long 40 char hashrefs, not 8 char abbreviated ones
"

help_usage "$@"

#min_args 1 "$@"

repos=()
check_gitlab=0
check_bitbucket=0
check_azure_devops=0
compare_by_date=0
long_hashrefs=0

for arg; do
    case "$arg" in
        -g|--gitlab)    check_gitlab=1
                        ;;
     -b|--bitbucket)    check_bitbucket=1
                        ;;
  -a|--azure-devops)    check_azure_devops=1
                        ;;
          -d|--date)    compare_by_date=1
                        shift || :
                        ;;
 -l|--long-hashrefs)    long_hashrefs=1
                        shift || :
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

if [ $compare_by_date = 1 ] && [ $long_hashrefs = 1 ]; then
    usage "--date and --long-hashrefs are mutually exclusive"
fi

check_gitlab(){
    [ $check_gitlab = 1 ]       && return 0
    [ $check_bitbucket = 0 ]    || return 1
    [ $check_azure_devops = 0 ] || return 1
    return 0
}

check_bitbucket(){
    [ $check_bitbucket = 1 ]    && return 0
    [ $check_gitlab = 0 ]       || return 1
    [ $check_azure_devops = 0 ] || return 1
    return 0
}

check_azure_devops(){
    [ $check_azure_devops = 1 ] && return 0
    [ $check_gitlab = 0 ]       || return 1
    [ $check_bitbucket = 0 ]    || return 1
    return 0
}

github_user="$(get_github_user)"

# need gitlab user
if check_gitlab; then
    gitlab_user="${GITLAB_USERNAME:-${GITLAB_USER:-}}"
    if [ -z "$gitlab_user" ]; then
        gitlab_user="$("$srcdir/../gitlab/gitlab_api.sh" "/user" | jq -r '.username')"
        gitlab_user="${gitlab_user:-<user>}"
    fi
fi

check_repos(){
    for repo in "$@"; do
        # very concise gives exactly the head hashref but no date
        #github_commits="$("$srcdir/github_api.sh" "/repos/$github_user/$repo/git/ref/heads/master")"
        github_commits="$("$srcdir/github_api.sh" "/repos/$github_user/$repo/commits/master?per_page=1")"
        if [ $compare_by_date = 1 ]; then
            # GitHub returns Z time
            github_master_ref="$(jq -r '.commit.committer.date' <<< "$github_commits")"
        else
            #github_master_ref="$(jq -r '.object.sha' <<< "$github_commits")"
            github_master_ref="$(jq -r '.sha' <<< "$github_commits")"
            if [ $long_hashrefs = 0 ]; then
                github_master_ref="${github_master_ref:0:8}"
            fi
        fi
        # don't printf as we go because it's harder to debug, instead collect the line and print in one go
        line="$(printf '%-26s\tGitHub: %s    ' "$github_user/$repo" "$github_master_ref")"
        in_sync=True
        if check_gitlab; then
            #gitlab_commits="$("$srcdir/../gitlab/gitlab_api.sh" "/projects/${gitlab_user}%2F$repo/repository/branches/master" 2>/dev/null || :)"
            gitlab_commits="$("$srcdir/../gitlab/gitlab_api.sh" "/projects/${gitlab_user}%2F$repo/repository/commits?ref_name=master&per_page=1" 2>/dev/null || :)"
            if [ $compare_by_date = 1 ]; then
                # GitHub returns current timezone eg. .000+01:00
                gitlab_master_ref="$(jq -r '.[0].committed_date' <<< "$gitlab_commits")"
                if [ -n "$gitlab_master_ref" ] && [ "$gitlab_master_ref" != null ]; then
                    gitlab_master_ref="$(date --utc -d "$gitlab_master_ref" '+%FT%TZ')"
                fi
            else
                # or .commit.short_id - only GitLab gives this short hashref in the API, we'll just truncate all of them to 8 chars for output
                # for /repository/branches/master endpoint
                #gitlab_master_ref="$(jq -r '.commit.id' <<< "$gitlab_commits")"
                gitlab_master_ref="$(jq -r '.[0].id' <<< "$gitlab_commits")"
                if [ $long_hashrefs = 0 ]; then
                    gitlab_master_ref="${gitlab_master_ref:0:8}"
                fi
            fi
            gitlab_master_ref="${gitlab_master_ref:-None}"
            line+="$(printf "GitLab: %-${#github_master_ref}s    " "$gitlab_master_ref")"
            if [ "$gitlab_master_ref" != "$github_master_ref" ]; then
                in_sync=False
            fi
        fi
        if check_bitbucket; then
            #bitbucket_commits=$("$srcdir/../bitbucket/bitbucket_api.sh" "/repositories/<user>/$repo/refs/branches/master?pagelen=1" 2>/dev/null || : )"
            bitbucket_commits="$("$srcdir/../bitbucket/bitbucket_api.sh" "/repositories/<user>/$repo/commits/master?pagelen=1" 2>/dev/null || : )"
            if [ $compare_by_date = 1 ]; then
                # BitBucket returns +00:00 timezone
                bitbucket_master_ref="$(jq -r '.values[0].date' <<< "$bitbucket_commits")"
                if [ -n "$bitbucket_master_ref" ] && [ "$bitbucket_master_ref" != null ]; then
                    bitbucket_master_ref="$(date --utc -d "$bitbucket_master_ref" '+%FT%TZ')"
                fi
            else
                # for refs/branches/master endpoint
                #bitbucket_master_ref="$(jq -r '.target.hash' <<< "$bitbucket_commits" || echo None)"
                bitbucket_master_ref="$(jq -r '.values[0].hash' <<< "$bitbucket_commits")"
                if [ $long_hashrefs = 0 ]; then
                    bitbucket_master_ref="${bitbucket_master_ref:0:8}"
                fi
            fi
            bitbucket_master_ref="${bitbucket_master_ref:-None}"
            line+="$(printf "BitBucket: %-${#github_master_ref}s    " "$bitbucket_master_ref")"
            if [ "$bitbucket_master_ref" != "$github_master_ref" ]; then
                in_sync=False
            fi
        fi
        if check_azure_devops; then
            # Bug in Azure DevOps API: returns commits in timestamped order to second resolution,so if two commits have the same timestamp, you may get the wrong one
            # https://developercommunity.visualstudio.com/content/problem/508507/azure-devops-rest-api-returns-commits-in-incorrect.html
            azure_devops_commits="$("$srcdir/../azure_devops/azure_devops_api.sh" "/{user}/{project}/_apis/git/repositories/$repo/commits?api-version=6.1-preview.1&searchCriteria.\$top=1&searchCriteria.compareVersion.version=master&searchCriteria.compareVersion.versionType=branch"  2>/dev/null || :)"
            azure_devops_commits="$("$srcdir/../azure_devops/azure_devops_api.sh" "/{user}/{project}/_apis/git/repositories/$repo/commits?\$top=1&branch=master"  2>/dev/null || :)"
            if [ $compare_by_date = 1 ]; then
                azure_devops_master_ref="$(jq -r '.value[0].committer.date' <<< "$azure_devops_commits")"
                if [ -n "$azure_devops_master_ref" ] && [ "$azure_devops_master_ref" != null ]; then
                    azure_devops_master_ref="$(date --utc -d "$azure_devops_master_ref" '+%FT%TZ')"
                fi
            else
                azure_devops_master_ref="$(jq -r '.value[0].commitId' <<< "$azure_devops_commits")"
                if [ $long_hashrefs = 0 ]; then
                    azure_devops_master_ref="${azure_devops_master_ref:0:8}"
                fi
            fi
            azure_devops_master_ref="${azure_devops_master_ref:-None}"
            line+="$(printf "Azure_DevOps: %-${#github_master_ref}s    " "$azure_devops_master_ref")"
            if [ "$azure_devops_master_ref" != "$github_master_ref" ]; then
                in_sync=False
            fi
        fi
        printf '%sIn-Sync: %s\n' "$line" "$in_sync"
    done
}

if [ "${#repos[@]}" -gt 0 ]; then
    check_repos "${repos[@]}"
else
    # want splitting
    # shellcheck disable=SC2046
    check_repos $(get_github_repos "$github_user")
fi
