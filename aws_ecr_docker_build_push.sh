#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-10-22 15:11:27 +0100 (Fri, 22 Oct 2021)
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
srcdir="$(dirname "${BASH_SOURCE[0]}")"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Builds the local docker image using the Dockerfile in the current directory and pushes it to the AWS ECR registry

Tags the docker image using the Git full hashref as well as 'latest', plus any Git tags if found for easy versioning support, and pushes all tags to AWS ECR

Requires AWS CLI to be installed and configured, as well as Docker to be running locally
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<ecr_registry> <repo>"

help_usage "$@"

min_args 2 "$@"

ECR="$1"
REPO="$2"

# $AWS_DEFAULT_REGION should be set in env or profile
aws ecr get-login-password | docker login --username AWS --password-stdin "$ECR"

hashref="$(git rev-parse HEAD)"
tags="$(git tag --points-at HEAD)"

docker build -t "$ECR/$REPO:$hashref" .

for tag in latest $tags; do
    docker tag "$ECR/$REPO:$hashref" "$ECR/$REPO:$tag"
done

docker push "$ECR/$REPO:$hashref"

for tag in latest $tags; do
    docker push "$ECR/$REPO:$tag"
done
