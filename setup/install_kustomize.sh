#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-27 12:08:44 +0100 (Thu, 27 Aug 2020)
#
#  https://github.com/HariSekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

cd /tmp

# https://kubernetes-sigs.github.io/kustomize/installation/binaries/

date "+%F %T  downloading kustomize"
# now installs to /private and fails as user :-/
#curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash

# Kustomize 3.5.x gets an error like this when using kustomization.yaml with a double slash in the URL:
#
#     Error: accumulating resources: accumulateFile "accumulating resources from 'github.com/argoproj/argo-cd//manifests/cluster-install?ref=v2.0.3': evalsymlink failure on '/tmp/git@repo/argocd/overlay/github.com/argoproj/argo-cd/manifests/cluster-install?ref=v2.0.3' : lstat /tmp/git@repo/argocd/overlay/github.com: no such file or directory", accumulateDirector: "recursed accumulation of path '/tmp/kustomize-881686007/repo': accumulating resources: accumulateFile \"accumulating resources from '../namespace-install': evalsymlink failure on '/tmp/kustomize-881686007/namespace-install' : lstat /tmp/kustomize-881686007/namespace-install: no such file or directory\", loader.New \"Error loading ../namespace-install with git: url lacks host: ../namespace-install, dir: evalsymlink failure on '/tmp/kustomize-881686007/namespace-install' : lstat /tmp/kustomize-881686007/namespace-install: no such file or directory, get: invalid source string: ../namespace-install\""
#
VERSION="${1:-4.1.3}"

os="$(uname -s | tr '[:upper:]' '[:lower:]')"

url="https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv$VERSION/kustomize_v${VERSION}_${os}_amd64.tar.gz"

cd /tmp

wget "$url" -O kustomize.tar.gz

date "+%F %T  unpacking kustomize"
tar zxvf kustomize.tar.gz

mkdir -pv ~/bin
unalias mv &>/dev/null || :
mv -vf kustomize ~/bin/

rm -f kustomize.tar.gz

echo

# called as part of download script - call manually now
~/bin/kustomize version -
