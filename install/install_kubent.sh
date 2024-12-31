#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-01-01 03:26:36 +0700 (Wed, 01 Jan 2025)
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
Installs Kube-No-Trouble from GitHub binary releases
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<version>]"

export PATH="$PATH:$HOME/bin"

help_usage "$@"

max_args 1 "$@"

#version="${1:-0.7.3}"
version="${1:-latest}"

export ARCH_X86_64=amd64
export OS_DARWIN=darwin

export RUN_VERSION_OPT=1

"$srcdir/../github/github_install_binary.sh" doitintl/kube-no-trouble "kubent-{version}-{os}-{arch}.tar.gz" "$version" "kubent"
echo
