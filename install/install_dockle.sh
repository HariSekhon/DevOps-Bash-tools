#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-01-11 10:07:36 +0000 (Tue, 11 Jan 2022)
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
Installs Dockle

https://github.com/goodwithtech/dockle
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<version>]"

export PATH="$PATH:$HOME/bin"

help_usage "$@"

#version="${1:-0.4.11}"
version="${1:-latest}"

export ARCH_X86=32bit
export ARCH_X86_64=64bit
export OS_DARWIN=macOS
export OS_LINUX=Linux

export RUN_VERSION_OPT=1

"$srcdir/../github/github_install_binary.sh" goodwithtech/dockle "dockle_{version}_{os}-{arch}.tar.gz" "$version" dockle
