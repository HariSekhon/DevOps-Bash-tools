#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-09-15 14:52:47 +0100 (Tue, 15 Sep 2020)
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
Creates Date and Timestamp tags for a Docker Image on Google Cloud Registry, based on the created time (either uploaded or created by Google Cloud Build)

Tags are in the format:

YYYY-MM-DD
YYYY-MM-DDTHHMMSSZ  (standard ISO UTC time without semi-colons which are invalid in docker tags)

The timestamp will be normalized to UTC

Requires GCloud SDK to be installed and configured
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<gcr.io>/<project_id>/<image>:<tag>"

help_usage "$@"

min_args 1 "$@"

image_tag="$1"

if ! [[ "$image_tag" =~ ^([^\.]+\.)?gcr\.io/[^/]+/[^:]+:.+$ ]]; then
    usage 'unrecognized GCR image:tag name - should be in a format matching this regex: ^([^\.]+\.)?gcr\.io/[^/]+/[^:]+:.+$'
fi

docker_image="${image_tag%%:*}"
tag="${image_tag##*:}"

timestamp="$(gcloud container images list-tags "$docker_image" --limit 10 --format='get(timestamp.datetime)' --filter="tags=$tag")"
if [ -z "$timestamp" ]; then
	echo "Failed to determine timestamp from Cloud Build for image '$docker_image' with tag '$tag'"
	exit 1
fi
if ! [[ "$timestamp" =~ ^[[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2}[[:space:]][[:digit:]]{2}:[[:digit:]]{2}:[[:digit:]]{2}[+-][[:digit:]]{2}:[[:digit:]]{2}$ ]]; then
	echo "Cloud Build timestamp not in expect YYYY-MM-DD HH:MM:SS[+-]HH:MM format, API may have changed"
	exit 1
fi

if is_mac; then
    date(){
        gdate "$@"
    }
fi

# normalize to UTC
timestamp="$(date --utc --date="$timestamp" '+%FT%H%M%SZ')"

date="${timestamp%T*}"

echo "tagging docker image $docker_image:$tag with extra tags: $date $timestamp"
# --quiet otherwise prompts Y/n which would hang build
gcloud container images add-tag --quiet \
	"$docker_image:$tag" \
		"$docker_image:$date" \
		"$docker_image:$timestamp"
		#"$docker_image:latest"
