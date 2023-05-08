#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: harisekhon
#
#  Author: Hari Sekhon
#  Date: 2020-09-14 16:14:36 +0100 (Mon, 14 Sep 2020)
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

# shellcheck disable=SC2034,SC2154
usage_description="
Tool to search DockerHub repos and return a configurable number of results using the Docker API

Mimics 'docker search' results format but more flexible

Older Docker CLI didn't support configuring the returned number of search results and always returned 25:

https://github.com/docker/docker/issues/23055

See also:

    dockerhub_search.py

in the DevOps Python tools repo - https://github.com/HariSekhon/DevOps-Python-tools
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="search terms"

help_usage "$@"

min_args 1 "$@"

query=""
verbose=0
limit=25

until [ $# -lt 1 ]; do
    case $1 in
    -h|--help)  usage
                ;;
   -l|--limit)  limit="$2"
                shift || :
                ;;
 -v|--verbose)  verbose=1
                ;;
           -*)  usage "unknown argument: $1"
                ;;
            *)  query+="%20$1"
                ;;
    esac
    shift || :
done

if ! is_int "$limit"; then
    usage "--num is not an integer"
fi

query="${query#%20}"

page=1

# starter value, will be overriden on first iteration
num_pages=100

results=0

printf '%-30s   %-45s   %-7s   %-8s   %-10s\n' "NAME" "DESCRIPTION" "STARS" "OFFICIAL" "AUTOMATED"

while [ $results -lt "$limit" ] &&
      [ "$page" -le "$num_pages" ]; do
    output="$(curl -sSL --fail --connect-timeout 3 "https://index.docker.io/v1/search?q=$query&page=${page}&n=100")"
    num_pages="$(jq -r .num_pages <<< "$output")"
    ((page+=1))
    while read -r name stars official automated description; do
        ((results += 1))
        if [ $results -gt "$limit" ]; then
            break 2
        fi
        if [ "${#description}" -gt 45 ]; then
            description="${description:0:42}..."
        fi
        if [ "$official" = true ]; then
            official="[OK]"
        else
            official=""
        fi
        if [ "$automated" = true ]; then
            automated="[OK]"
        else
            automated=""
        fi
        printf '%-30s   %-45s   %-7s   %-8s   %-10s\n' "$name" "$description" "$stars" "$official" "$automated"
    done < <(jq -r '.results[] | [.name, .star_count, .is_official, .is_automated, .description] | @tsv' <<< "$output")
done

if [ $verbose = 1 ]; then
    echo
    echo "Results Shown: $results"
    echo "Total Results: $(jq -r .num_results <<< "$output")"
fi
