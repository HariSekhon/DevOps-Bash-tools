#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: https://hub.docker.com/v2/repositories/library/centos
#
#  Author: Hari Sekhon
#  Date: 2020-09-30 11:08:01 +0100 (Wed, 30 Sep 2020)
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
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Lists tags for a given Docker Registry image using the Docker Registry API

Example:

Official images must be prefixed with 'library/':

    ${0##*/} https://hub.docker.com/v2/repositories/library/centos

    ${0##*/} https://hub.docker.com/v2/repositories/library/ubuntu

User images are prefixed with '<username>/':

    ${0##*/} https://hub.docker.com/v2/repositories/harisekhon/hbase


See also:

- dockerhub_show_tags.sh:

    ddockerhub_show_tags.sh harisekhon/hbase

- Skopeo:

    skopeo inspect docker://harisekhon/hbase | jq -r '.RepoTags[]'
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="https://host:port/v2/repository/<repo>/<image> [<curl_options>]"

help_usage "$@"

min_args 1 "$@"

url="$1"
shift || :

get_tags(){
    local url="$1"
    local output
    shift || :
    output="$("$srcdir/docker_api.sh" "$url" "$@")"
    tags="$(jq -r '.results[].name' <<< "$output")"
    if [ -z "$tags" ]; then
        die "no tags returned for url '$url'"
    fi
    echo "$tags"
    next="$(jq -r .next <<< "$output")"
    if [ -n "$next" ] && [ "$next" != null ]; then
        get_tags "$next"
    fi
}

get_tags "$url/tags" "$@"
