#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-02-07 15:01:31 +0000 (Fri, 07 Feb 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Script to generate status.md at top level
set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

top_N=20

repolist=""

get_repos(){
    page=1
    while true; do
        echo "fetching repos page $page" >&2
        # use authenticated requests if you are hitting the API rate limit
        # eg. CURL_OPTS="-u harisekhon:$GITHUB_TOKEN" ...
        # shellcheck disable=SC2086
        if ! output="$(curl -sS --connect-timeout 3 ${CURL_OPTS:-} "https://api.github.com/users/HariSekhon/repos?page=$page&per_page=100")"; then
            echo "ERROR" >&2
            exit 1
        fi
        if [ -z "$(jq '.[]' <<< "$output")" ]; then
            break
        elif jq -r '.message' <<< "$output" >&2 2>/dev/null; then
            exit 1
        fi
        jq -r '.[] | select(.fork | not) | [.name, .stargazers_count] | @tsv' <<< "$output"
        ((page+=1))
    done
}

repolist="$(get_repos | grep -v spark-apps | sort -k2nr | awk '{print $1}' | head -n "$top_N")"

#echo "$repolist" >&2

# make portable between linux and mac
head(){
    if [ "$(uname -s)" = Darwin ]; then
        ghead
    else
        command head
    fi
}

for repo in $repolist; do
    echo "getting repo $repo" >&2
    curl -sS "https://raw.githubusercontent.com/HariSekhon/$repo/master/README.md" |
    sed -n '1,/^[^\[[:space:]=]/ p' |
    head -n -1 |
    perl -np -e 'print unless /=============/' |
    sed '1 s/^/# /'
    echo
    echo
done |
tee "$srcdir/../Status.md"
