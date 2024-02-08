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

# https://kubernetes-sigs.github.io/kustomize/installation/binaries/

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/../lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Installs Kustomize
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<version>]"

help_usage "$@"

#min_args 1 "$@"

#version="${1:-4.4.1}"
version="${1:-latest}"

owner_repo="kubernetes-sigs/kustomize"

# XXX can't use github_install_binary.sh because Kustomize repo intermixes kustomize and kyaml releases, so much filter the latest version, then strip the kustomize/ prefix in the version tag

if [ "$version" = latest ]; then
    timestamp "determining latest version of '$owner_repo' via GitHub API"
    version="$("$srcdir/../github/github_repo_latest_release_filter.sh" "$owner_repo" "kustomize")"
    version="${version##*/}"
    timestamp "latest version is '$version'"
else
    is_semver "$version" || die "non-semver version argument given: '$version' - should be in format: N.N.N"
    [[ "$version" =~ ^v ]] || version="v$version"
fi

# now installs to /private and fails as user :-/
#curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash

# Kustomize 3.5.x gets an error like this when using kustomization.yaml with a double slash in the URL:
#
#     Error: accumulating resources: accumulateFile "accumulating resources from 'github.com/argoproj/argo-cd//manifests/cluster-install?ref=v2.0.3': evalsymlink failure on '/tmp/git@repo/argocd/overlay/github.com/argoproj/argo-cd/manifests/cluster-install?ref=v2.0.3' : lstat /tmp/git@repo/argocd/overlay/github.com: no such file or directory", accumulateDirector: "recursed accumulation of path '/tmp/kustomize-881686007/repo': accumulating resources: accumulateFile \"accumulating resources from '../namespace-install': evalsymlink failure on '/tmp/kustomize-881686007/namespace-install' : lstat /tmp/kustomize-881686007/namespace-install: no such file or directory\", loader.New \"Error loading ../namespace-install with git: url lacks host: ../namespace-install, dir: evalsymlink failure on '/tmp/kustomize-881686007/namespace-install' : lstat /tmp/kustomize-881686007/namespace-install: no such file or directory, get: invalid source string: ../namespace-install\""

export RUN_VERSION_ARG=1

"$srcdir/../packages/install_binary.sh" "https://github.com/$owner_repo/releases/download/kustomize%2F$version/kustomize_${version}_{os}_amd64.tar.gz" kustomize
