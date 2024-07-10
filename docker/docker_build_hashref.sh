#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-07-10 18:12:25 +0200 (Wed, 10 Jul 2024)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
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
. "$srcdir/lib/git.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Runs Docker Build and auto-generates docker image name and tag from relative Git path and commit short SHA

If it's a dirty checkout with added / modified files then appends '-dirty-<checksum>' to the docker tag
where '<checksum>' is another short hash of the Git status porcelain to differentiate it from the clean unmodified commit version

Useful to compare docker image sizes between your clean and modified versions of Dockerfile or contents

If you want to set the docker image name instead of letting it default to the git relative root dir, then
set the environment variable:

    export DOCKER_BUILD_IMAGE_NAME=...

The dirty commit only hashes which files were added / changed, not their content changes
If you really want the hash to change for any differing content changes, then set the environment variable:

    export DOCKER_BUILD_HASH_CONTENTS=1
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<context_path>]"

help_usage "$@"

max_args 1 "$@"

context_dir="${1:-.}"

if ! is_in_git_repo; then
    die "Not in a Git repo to auto-determine the Git short sha and relative path for docker image naming"
fi

git_commit_short_sha="$(git_commit_short_sha)"

image_name="${DOCKER_BUILD_IMAGE_NAME:-}"

if is_blank "$image_name"; then
    git_relative_dir="$(git_relative_dir)"

    image_name="${git_relative_dir////--}"
fi

dirty=""
if git status --porcelain | grep -q . ; then
  if [ "${DOCKER_BUILD_HASH_CONTENTS:-}" = 1 ]; then
    git_root="$(git_root)"
    # prepend the git root dir to each file because 'git status --porcelain' gives from relative root of repo
    # then cat each file and pipe them all into md5sum to detect any content differences in the git repo for a unique hashref
    dirty="-dirty-$(git status --porcelain | cut -c 4- | sed "s|^|$git_root/|" | xargs cat | md5sum | cut -c 1-7)"
  else
    # if 7 char short hash is good enough for Git then it's good enough for me
    dirty="-dirty-$(git status --porcelain | md5sum | cut -c 1-7)"
  fi
fi

set -x
docker build "$context_dir" -t "${image_name}:${git_commit_short_sha}${dirty}"

docker images | grep "^$image_name"
