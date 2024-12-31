#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-27 12:08:44 +0100 (Thu, 27 Aug 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://cert-manager.io/docs/usage/kubectl-plugin/

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/../lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Installs Kubernetes 'kubectl' plugin for cert-manager
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<version>]"

export HOME="${HOME:-$(cd && pwd)}"

export PATH="$PATH:$HOME/bin"

help_usage "$@"

#version="${1:-1.1.0}"
version="${1:-latest}"

binary="kubectl-cert_manager"

if ! type -P kubectl &>/dev/null; then
    timestamp "Kubectl not installed, pre-installing..."
    echo
    "$srcdir/install_kubectl.sh"
    echo
fi

# can rusult in error trying to contact k8s cluster
#export RUN_VERSION_ARG=1

"$srcdir/../github/github_install_binary.sh" cert-manager/cert-manager 'kubectl-cert_manager-{os}-{arch}.tar.gz' "$version" "$binary"
