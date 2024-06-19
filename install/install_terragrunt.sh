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

# shellcheck disable=SC1090,SC1091
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

export RUN_VERSION_OPT=1

"$srcdir/../github/github_install_binary.sh" gruntwork-io/terragrunt 'terragrunt_{os}_{arch}' "$version" terragrunt

#echo
#terragrunt --install-autocomplete
