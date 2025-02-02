#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2023-05-28 16:27:26 +0100 (Sun, 28 May 2023)
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
. "$srcdir/../lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Installs Hashicorp Packer

Homebrew no longer has recent Packer versions past 1.9.4 due to a change in license to be non-free

So this downloads newer versions
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<version>]"

export PATH="$PATH:$HOME/bin"

help_usage "$@"

#version="${1:-1.8.7}"
version="${1:-latest}"

owner_repo="hashicorp/packer"

if [ "$version" = latest ]; then
    timestamp "determining latest version of '$owner_repo' via GitHub API"
    version="$("$srcdir/../github/github_repo_latest_release.sh" "$owner_repo")"
    version="${version#v}"  # https://releases.hashicorp.com doesn't use v prefix but github does
    timestamp "latest version is '$version'"
else
    is_semver "$version" || die "non-semver version argument given: '$version' - should be in format: N.N.N"
fi

# gives just version number
#export RUN_VERSION_OPT=1
# prefixes with Packer
export RUN_VERSION_ARG=1

"$srcdir/../packages/install_binary.sh" "https://releases.hashicorp.com/packer/$version/packer_${version}_{os}_{arch}.zip" packer
