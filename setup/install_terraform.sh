#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019/09/20
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

# shellcheck disable=SC1090,SC1091
. "$srcdir/../lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Installs Terraform

Can optionally specify an exact version to install instead of latest (auto-determines latest release)
"

#If the 'terraform' binary is already found on \$PATH, aborts for safety as Terraform version upgrades affect the state file
#Set UPDATE_TERRAFORM=1 in the environment to upgrade the Terraform version

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<version>]"

help_usage "$@"

#version="${1:-${TERRAFORM_VERSION:-${VERSION:-0.12.29}}}"
#version="${1:-${TERRAFORM_VERSION:-${VERSION:-0.14.5}}}"
#version="${1:-${TERRAFORM_VERSION:-${VERSION:-1.1.2}}}"
version="${1:-${TERRAFORM_VERSION:-latest}}"

owner_repo="hashicorp/terraform"

if [ "$version" = latest ]; then
    timestamp "determining latest version of '$owner_repo' via GitHub API"
    version="$("$srcdir/../github/github_repo_latest_release.sh" "$owner_repo")"
    version="${version#v}"
    timestamp "latest version is '$version'"
else
    is_semver "$version" || die "non-semver version argument given: '$version' - should be in format: N.N.N"
fi

#if [ -z "${UPDATE_TERRAFORM:-}" ]; then
#    # command -v catches aliases, not suitable
#    # shellcheck disable=SC2230
#    if type -P "$binary" &>/dev/null; then
#        echo "Terraform binary '$binary' is already installed and available in \$PATH"
#        echo
#        echo "To add or overwrite regardless, set the below variable and then re-run this script:"
#        echo
#        echo "export UPDATE_TERRAFORM=1"
#        exit 0
#    fi
#fi

export RUN_VERSION_ARG=1

"$srcdir/../packages/install_binary.sh" "https://releases.hashicorp.com/terraform/$version/terraform_${version}_{os}_{arch}.zip" terraform
