#!/usr/bin/env bash
#
#  Author: Hari Sekhon
#  Date: 2020-03-19 19:31:41 +0000 (Thu, 19 Mar 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying LICENSE file
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/../lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Installs Docker Compose
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<version>]"

export PATH="$PATH:$HOME/bin"

help_usage "$@"

#min_args 1 "$@"

#version="${1:-2.4.0}"
version="${1:-latest}"

owner_repo="docker/compose"

if [ "$version" = latest ]; then
    timestamp "determining latest version of '$owner_repo' via GitHub API"
    version="$("$srcdir/../github_repo_latest_release.sh" "$owner_repo")"
    timestamp "latest version is '$version'"
else
    is_semver "$version" || die "non-semver version argument given: '$version' - should be in format: N.N.N"
    version="v$version"
fi

arch="$(get_arch)"
if [ "$arch" = amd64 ]; then
    arch=x86_64
fi

"$srcdir/../install_binary.sh" "https://github.com/docker/compose/releases/download/$version/docker-compose-{os}-$arch" "docker-compose"

echo
docker-compose version
