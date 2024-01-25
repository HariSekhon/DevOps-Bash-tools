#!/usr/bin/env bash
# vim:ts=4:sts=4:sw=4:et
# shellcheck disable=SC2230
# command -v catches aliases, not suitable
#
#  Author: Hari Sekhon
#  Date: 2020-12-11 11:59:42 +0000 (Fri, 11 Dec 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying LICENSE file
#
#  https://www.linkedin.com/in/HariSekhon
#

#"$srcdir/install_homebrew.sh"
#brew tap weaveworks/tap
#brew install weaveworks/tap/eksctl
#brew upgrade eksctl
#brew link --overwrite eksctl

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/../lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Installs AWS eksctl CLI from WeaveWorks
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<version>]"

export PATH="$PATH:$HOME/bin"

help_usage "$@"

#version="${1:-2.4.0}"
version="${1:-latest}"

export RUN_VERSION_ARG=1

"$srcdir/../github/github_install_binary.sh" weaveworks/eksctl 'eksctl_{os}_{arch}.tar.gz' "$version" eksctl
