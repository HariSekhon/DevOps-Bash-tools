#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-05-01 23:31:03 +0400 (Wed, 01 May 2024)
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
Installs Rancher CLI

As of version 2.8.3 there is no macOS Arm binary available for download, so downloads the amd64 binary which works

Once installed, configure authentication by creating a personal Access Key and Secret Key here:

    https://\$RANCHER_HOST:\$RANCHER_PORT/dashboard/account

and then authenticating using them like so:

    rancher login \"https://\$RANCHER_HOST\" --token \"\$RANCHER_ACCESS_KEY:\$RANCHER_SECRET_KEY\"

See Rancher knowledge base page for CLI usage info and examples:

    https://github.com/HariSekhon/Knowledge-Base/blob/main/rancher.md

For Rancher itself, see Kubernetes configs with Kustomize and Helm in the repo:

    https://github.com/HariSekhon/Kubernetes-configs
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<version>]"

export PATH="$PATH:$HOME/bin"

help_usage "$@"

#version="${1:-2.8.3}"
version="${1:-latest}"

export ARCH_X86_64=amd64
export ARCH_ARM64=arm  # not present so override back to amd64 below and use rosetta
export ARCH_OVERRIDE=amd64

export RUN_VERSION_OPT=1

"$srcdir/../github/github_install_binary.sh" rancher/cli "rancher-{os}-{arch}-v{version}.tar.gz" "$version" "rancher-v{version}/rancher"
