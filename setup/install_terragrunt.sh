#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-07-07 19:08:50 +0100 (Thu, 07 Jul 2022)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying LICENSE file
#
#  https://www.linkedin.com/in/HariSekhon
#

# Installs Terragrunt on Mac / Linux
#
# If running as root, installs to /usr/local/bin
#
# If running as non-root, installs to $HOME/bin

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/../lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Installs Terragrunt

Can optionally specify an exact version to install instead of latest (auto-determines latest release)
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<version>]"

help_usage "$@"

#version="${1:-${TERRAGRUNT_VERSION:-${VERSION:-0.38.4}}}"
version="${1:-${TERRAGRUNT_VERSION:-latest}}"

owner_repo="gruntwork-io/terragrunt"

if [ "$version" = latest ]; then
    timestamp "determining latest version of '$owner_repo' via GitHub API"
    version="$("$srcdir/../github_repo_latest_release.sh" "$owner_repo")"
    version="${version#v}"
    timestamp "latest version is '$version'"
else
    is_semver "$version" || die "non-semver version argument given: '$version' - should be in format: N.N.N"
fi

export RUN_VERSION_OPT=1

"$srcdir/../install_binary.sh" "https://github.com/$owner_repo/releases/download/v$version/terragrunt_{os}_{arch}" terragrunt
