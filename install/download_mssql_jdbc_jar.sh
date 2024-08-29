#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: Mon Aug 26 16:57:51 2024 +0200
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
Quickly determines and downloads latest Microsoft SQL Server JDBC jar or an explicitly given version

Useful to get the jar to upload to data integration 3rd party directories or Docker images or Kubernetes

Version defaults to 'latest' in which case it determines the latest version from GitHub releases

JRE version defaults to 8
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<version> <jre_version>]"

#version="${1:-42.2.18}"
version="${1:-latest}"
jre_version="${2:-8}"

github_owner_repo="microsoft/mssql-jdbc"

"$srcdir/../github/github_download_release_jar.sh" "https://github.com/$github_owner_repo/releases/download/v{version}/mssql-jdbc-{version}.jre$jre_version.jar" "$version"
