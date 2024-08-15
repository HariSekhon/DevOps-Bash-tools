#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-12-07 23:00:59 +0000 (Mon, 07 Dec 2020)
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

top_N=20

# shellcheck disable=SC2034,SC2154
usage_description="
Script to generate STARCHARTS.md containing the star graphs of the Top N GitHub repos on a single page


# Examples:


    Without arguments queries for all non-fork repos for your \$GITHUB_USER and iterate them up to $top_N to generate the page

        GITHUB_USER=HariSekhon ./github_generate_status_page.sh
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

trap 'echo ERROR >&2' exit

file="STARCHARTS.md"

# this leads to confusion as it generates some randomly unexpected output by querying a github user who happens to have the same name as your local user eg. hari, so force explicit now
#USER="${GITHUB_USER:-${USERNAME:-${USER}}}"
if [ -z "${GITHUB_USER:-}" ] ; then
    GITHUB_USER="$(get_github_user || :)"
fi
if is_blank "${GITHUB_USER:-}" || [ "$GITHUB_USER" = null ]; then
    echo "\$GITHUB_USER not set!"
    exit 1
fi

get_repos(){
    page=1
    while true; do
        echo "fetching GitHub repos - page $page" >&2
        if ! output="$("$srcdir/github_api.sh" "/users/$GITHUB_USER/repos?page=$page&per_page=100")"; then
            echo "ERROR" >&2
            exit 1
        fi
        # use authenticated requests if you are hitting the API rate limit - this is automatically done above now if USER/PASSWORD GITHUB_USER/GITHUB_PASSWORD/GITHUB_TOKEN environment variables are detected
        # eg. CURL_OPTS="-u harisekhon:$GITHUB_TOKEN" ...
        if [ -z "$(jq '.[]' <<< "$output")" ]; then
            break
        elif jq -r '.message' <<< "$output" >&2 2>/dev/null; then
            exit 1
        fi
        jq -r '.[] | select(.fork | not) | select(.private | not) | [.full_name, .stargazers_count, .forks] | @tsv' <<< "$output"
        ((page+=1))
    done
}

repolist="$(get_repos | grep -v spark-apps | sort -k2nr -k3nr | awk '{print $1}' | head -n "$top_N")"

num_repos="$(wc -w <<< "$repolist")"
num_repos="${num_repos// /}"

# make portable between linux and mac
head(){
    if [ "$(uname -s)" = Darwin ]; then
        # from brew's coreutils package (installed by 'make')
        ghead "$@"
    else
        command head "$@"
    fi
}

tempfile="$(mktemp)"
trap 'echo ERROR >&2; rm -vf -- "$tempfile"' exit

{
actual_repos=0

total_stars=0
total_forks=0
echo "getting followers" >&2
followers="$("$srcdir/github_api.sh" /users/harisekhon | jq -r .followers)"

echo "---" >&2
for repo in $repolist; do
    if ! [[ "$repo" =~ / ]]; then
        repo="$GITHUB_USER/$repo"
    fi
    echo "fetching GitHub repo info for '$repo'" >&2
    repo_json="$("$srcdir/github_api.sh" "/repos/$repo")"
    description="$(jq -r .description <<< "$repo_json")"
    stars="$(jq -r .stargazers_count <<< "$repo_json")"
    forks="$(jq -r .forks <<< "$repo_json")"
    #watchers="$(jq -r .watchers <<< "$repo_json")"
    ((total_stars += stars))
    ((total_forks += forks))
    #((total_watchers += watchers))
    echo "fetching GitHub README.md for '$repo'" >&2
    echo "---"
    echo "---" >&2
    title="$(curl -sS --fail "https://raw.githubusercontent.com/$repo/master/README.md" | { head -n1 | sed 's/^#*//'; cat >/dev/null; } )"
    title="${title## }"
    title="${title%% }"
    printf '## %s\n' "$title"
    printf '
[![Repo on GitHub](https://img.shields.io/badge/GitHub-repo-blue?logo=github)](https://github.com/%s)
[![GitHub stars](https://img.shields.io/github/stars/%s?logo=github)](https://github.com/%s/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/%s?logo=github)](https://github.com/%s/network)
' "$repo" "$repo" "$repo" "$repo" "$repo"
    echo
    #printf '%s\n' "Link:  [$repo](https://github.com/$repo)"
    #echo
    printf '%s\n' "$description"
    echo
    printf '%s\n' "[![Stargazers over time](https://starchart.cc/$repo.svg)](https://starchart.cc/$repo)"
    echo
    ((actual_repos+=1))
done
} > "$tempfile"

if [ "$num_repos" != "$actual_repos" ]; then
    echo "ERROR: differing number of target github repos ($num_repos) vs actual repos ($actual_repos)"
    exit 1
fi

{
cat <<EOF
# GitHub StarCharts

![Original Repos](https://img.shields.io/badge/Repos-$actual_repos-blue?logo=github)
![Stars](https://img.shields.io/badge/Stars-$total_stars-blue?logo=github)
![Forks](https://img.shields.io/badge/Forks-$total_forks-blue?logo=github)
![Followers](https://img.shields.io/badge/Followers-$followers-blue?logo=github)
[![Azure DevOps Profile](https://img.shields.io/badge/Azure%20DevOps-HariSekhon-0078D7?logo=azure%20devops)](https://dev.azure.com/harisekhon/GitHub)
[![GitHub Profile](https://img.shields.io/badge/GitHub-HariSekhon-2088FF?logo=github)](https://github.com/HariSekhon)
[![GitLab Profile](https://img.shields.io/badge/GitLab-HariSekhon-FCA121?logo=gitlab)](https://gitlab.com/HariSekhon)
[![BitBucket Profile](https://img.shields.io/badge/BitBucket-HariSekhon-0052CC?logo=bitbucket)](https://bitbucket.org/HariSekhon)

[![GitStar Ranking Profile](https://img.shields.io/badge/GitStar%20Ranking-HariSekhon-blue?logo=github)](https://gitstar-ranking.com/HariSekhon)

[git.io/hari-starcharts](https://git.io/hari-starcharts) generated by \`${0##*/}\` in [HariSekhon/DevOps-Bash-tools](https://github.com/HariSekhon/DevOps-Bash-tools)

EOF
cat "$tempfile"
} | tee "$file"

rm -f -- "$tempfile"

untrap
