#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-02-17 04:27:10 +0700 (Mon, 17 Feb 2025)
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
Installs Firebase CLI binary from GitHub releases
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<version>]"

export PATH="$PATH:$HOME/bin"

help_usage "$@"

#version="${1:-13.31.1}"
version="${1:-latest}"

export OS_DARWIN=macos

export RUN_VERSION_OPT=1

#"$srcdir/../packages/install_binary.sh" "https://firebase.tools/bin/{os}/$version" firebase

#https://github.com/firebase/firebase-tools/releases/download/v13.31.1/firebase-tools-macos
"$srcdir/../github/github_install_binary.sh" firebase/firebase-tools "firebase-tools-{os}" "$version" firebase
