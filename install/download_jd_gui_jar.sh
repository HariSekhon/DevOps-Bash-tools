#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-08-28 20:57:31 +0200 (Wed, 28 Aug 2024)
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
Quickly determines and downloads latest JD GUI jar or an explicitly given version

Version defaults to 'latest' in which case it determines the latest version from GitHub releases
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<version>]"

version="${1:-latest}"

github_owner_repo="java-decompiler/jd-gui"

"$srcdir/../github/github_download_release_jar.sh" "https://github.com/$github_owner_repo/releases/download/v{version}/jd-gui-{version}-min.jar" "$version"
