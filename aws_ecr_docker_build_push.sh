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
Builds the local docker image using the Dockerfile and pushes it to the ECR registry and repo

Tags the build using the Git hashref as well as 'latest' and pushes both tags to ECR for tracking purposes

Requires AWS CLI to be installed and configured, as well as Docker to be running locally
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<ecr_registry> <repo>"

help_usage "$@"

min_args 2 "$@"

ECR="$1"
REPO="$2"

aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin "$ECR"

hashref="$(git rev-parse HEAD)"

docker build -t "$ECR/$REPO:$hashref" .

docker tag "$ECR/$REPO:$hashref" "$ECR/$REPO:latest"

docker push "$ECR/$REPO:$hashref"
docker push "$ECR/$REPO:latest"
