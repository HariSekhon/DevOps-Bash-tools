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

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/../lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Installs Kubernetes 'kubectl' CLI
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<kubectl_version> <cert_manager_plugin_version>]"

export PATH="$PATH:$HOME/bin"

help_usage "$@"

#min_args 1 "$@"

kubectl_version="${1:-latest}"

#cert_manager_version="${2:-1.1.0}"
cert_manager_version="${2:-latest}"

# =======================================================
# https://kubernetes.io/docs/tasks/tools/install-kubectl/

#if [ "$(uname -s)" = Darwin ]; then
#    curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/darwin/amd64/kubectl"
#else
#    curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
#fi

if [ "$kubectl_version" = latest ]; then
    kubectl_version="$(curl -sSL https://dl.k8s.io/release/stable.txt)"
    kubectl_version="${kubectl_version#v}"
    timestamp "latest version is '$kubectl_version'"
else
    is_semver "$kubectl_version" || die "non-semver version argument given: '$kubectl_version' - should be in format: N.N.N"
fi

"$srcdir/../install_binary.sh" "https://dl.k8s.io/release/v$kubectl_version/bin/{os}/{arch}/kubectl"

echo
~/bin/kubectl version --client
echo

# =======================================================
# https://cert-manager.io/docs/usage/kubectl-plugin/

owner_repo="cert-manager/cert-manager"

if [ "$cert_manager_version" = latest ]; then
    timestamp "determining latest version of '$owner_repo' via GitHub API"
    cert_manager_version="$("$srcdir/../github_repo_latest_release.sh" "$owner_repo")"
    cert_manager_version="${cert_manager_version#v}"
    timestamp "latest version is '$cert_manager_version'"
elif [[ "$kubectl_version" =~ ^v ]]; then
    cert_manager_version="v$cert_manager_version"
    is_semver "$cert_manager_version" || die "non-semver version argument given: '$cert_manager_version' - should be in format: N.N.N"
fi

"$srcdir/../install_binary.sh" "https://github.com/$owner_repo/releases/download/v$cert_manager_version/kubectl-cert_manager-{os}-{arch}.tar.gz" kubectl-cert_manager

echo
~/bin/kubectl-cert-manager version
