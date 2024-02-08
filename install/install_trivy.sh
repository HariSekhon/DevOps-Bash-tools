#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-01-10 19:07:22 +0000 (Mon, 10 Jan 2022)
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
Installs Trivy by AquaSec
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

#version="${1:-0.22.0}"
version="${1:-latest}"

export OS_DARWIN=macOS
export OS_LINUX=Linux
export ARCH_X86_64="64bit"
export ARCH_X86="32bit"
export ARCH_ARM64="ARM64"  # Trivy packages uppercase arm
export ARCH_ARM="ARM"

export RUN_VERSION_OPT=1

"$srcdir/../github/github_install_binary.sh" aquasecurity/trivy "trivy_{version}_{os}-{arch}.tar.gz" "$version" trivy
