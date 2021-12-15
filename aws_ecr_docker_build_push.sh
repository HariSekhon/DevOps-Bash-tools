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

Tags the docker image with the following and pushes all tags to AWS ECR:

	- latest
	- Git full hashref
	- Git branch
    - any Git tags, if found, for easy versioning support
	- date (YYYY-MM-DD)
	- datetimestamp (YYYYMMDDThhmmssZ] in UTC

Requires AWS CLI to be installed and configured, as well as Docker to be running locally
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<ecr_registry> <repo>"

help_usage "$@"

num_args 2 "$@"

ECR="$1"
REPO="$2"

if ! [[ "$ECR" =~ ^[[:digit:]]+.dkr.ecr.[[:alnum:]-]+.amazonaws.com$ ]]; then
    usage "Invalid ECR address given:  $ECR"
fi
if ! [[ "$REPO" =~ ^[[:alnum:]/-]+$ ]]; then
    usage "Invalid Repo name given:  $REPO"
fi

if is_CI; then
    docker version
    echo
fi

echo "* AWS ECR -> Docker login"
# $AWS_DEFAULT_REGION should be set in env or profile
aws ecr get-login-password | docker login --username AWS --password-stdin "$ECR"
echo

echo "* Determining tags"
hashref="$(git rev-parse HEAD)"
#
# adding tags:
#
# - git branch
# - any git tags
# - date
# - datetimestamp
#
# must use date -u switch since --utc only works on Linux and not Mac
tags="
$(git rev-parse --abbrev-ref HEAD)
$(git tag --points-at HEAD)
$(date -u '+%F')
$(date -u '+%FT%H%M%SZ')
"
echo

docker build -t "$ECR/$REPO:$hashref" .
echo

for tag in latest $tags; do
	echo "* Tagging as '$tag'"
    docker tag "$ECR/$REPO:$hashref" "$ECR/$REPO:$tag"
	echo
done

for tag in "$hashref" latest $tags; do
	echo "* Pushing tag '$tag'"
    docker push "$ECR/$REPO:$tag"
	echo
done
