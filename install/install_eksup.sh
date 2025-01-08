#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-01-08 08:28:50 +0700 (Wed, 08 Jan 2025)
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
Installs EKSup tool to analyze EKS clusters for upgrades
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<version>]"

export PATH="$PATH:$HOME/bin"

help_usage "$@"

max_args 1 "$@"

#version="${1:-0.9.0}"
version="${1:-latest}"

export ARCH_X86_64=x86_64
export ARCH_ARM64=aarch64

export RUN_VERSION_OPT=1

# awful naming convention variations:
#
#   https://github.com/clowdhaus/eksup/releases
#
if is_mac; then
    basename="eksup-v{version}-{arch}-apple-{os}"
else
    if uname -m | grep arm; then
        basename="eksup-v{version}-{arch}-unknown-{os}-gnueabihf"
    else
        basename="eksup-v{version}-{arch}-unknown-{os}-musl"
    fi
fi


"$srcdir/../github/github_install_binary.sh" clowdhaus/eksup "$basename.tar.gz" "$version" "$basename/eksup"
