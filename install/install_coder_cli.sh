#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-07-03 23:25:02 +0200 (Wed, 03 Jul 2024)
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
. "$srcdir/../lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Installs the Coder CLI via GitHub binary releases
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<version>]"

help_usage "$@"

max_args 1 "$@"

#version="${1:-2.13.0}"
version="${1:-latest}"

# on Mac just runs:
#
#   brew install coder/coder/coder
#
# which we can do via ../setup/brew-packages-desktop-taps.txt
#
#curl -L https://coder.com/install.sh | sh

export ARCH_X86_64=amd64
export ARCH_ARM64=amd64

export RUN_VERSION_ARG=1

ext="tar.gz"
if is_mac; then
    ext="zip"
fi

"$srcdir/../github/github_install_binary.sh" coder/coder "coder_{version}_{os}_{arch}.$ext" "$version" coder
