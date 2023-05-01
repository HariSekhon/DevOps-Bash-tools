#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: centos
#
#  Author: Hari Sekhon
#  Date: 2020-09-14 15:43:04 +0100 (Mon, 14 Sep 2020)
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
Lists tags for a given DockerHub image using the DockerHub API

Example:

    ${0##*/} centos

    ${0##*/} ubuntu

    ${0##*/} harisekhon/hbase


See also:

- dockerhub_show_tags.py in the DevOps Python tools repo:  https://github.com/HariSekhon/DevOps-Python-tools

    ddockerhub_show_tags.py harisekhon/hbase

- Skopeo

    skopeo inspect docker://harisekhon/hbase | jq -r '.RepoTags[]'
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="repo/image [<curl_options>]"

help_usage "$@"

min_args 1 "$@"

repo_image="$1"
shift || :

if ! [[ "$repo_image" =~ / ]]; then
    repo_image="library/$repo_image"
fi

get_tags(){
    local url_path="$1"
    local output
    shift || :
    output="$("$srcdir/dockerhub_api.sh" "$url_path" "$@")"
    jq -r '.results[].name' <<< "$output"
    next="$(jq -r .next <<< "$output")"
    if [ -n "$next" ] && [ "$next" != null ]; then
        get_tags "$next"
    fi
}

get_tags "/repositories/$repo_image/tags" "$@"
