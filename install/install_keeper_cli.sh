#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-03-05 14:29:41 +0700 (Wed, 05 Mar 2025)
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
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Downloads and runs the Keeper CLI installer on Mac

If not on Mac, tries to install Keeper CLI via Python pip
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<version>"

export PATH="$PATH:$HOME/bin"

help_usage "$@"

max_args 1 "$@"

#version="${1:-17.0.8}"
version="${1:-latest}"

if ! is_mac; then
    pip3 install keepercommander
    exit 0
fi

export OS_DARWIN=mac

owner_repo="Keeper-Security/Commander"

if [ "$version" = latest ]; then
    timestamp "determining latest version of '$owner_repo' via GitHub API"
    version="$("$srcdir/../github/github_repo_latest_release.sh" "$owner_repo")"
    timestamp "latest version is '$version'"
else
    is_semver "$version" || die "non-semver version argument given: '$version' - should be in format: N.N.N"
fi

if ! [[ "$version" =~ ^v ]]; then
    version="v$version"
fi

arch="$(get_arch)"

download_url="https://github.com/$owner_repo/releases/download/$version/keeper-commander-mac-$arch-$version.pkg"
file="${download_url##*/}"

"$srcdir/../bin/download_url_file.sh" "$download_url"

open "$file"
