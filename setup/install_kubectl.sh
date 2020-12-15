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

cert_manager_version="1.1.0"

platform="$(uname -s | tr '[:upper:]' '[:lower:]')"

cd /tmp

# =======================================================
# https://kubernetes.io/docs/tasks/tools/install-kubectl/

#if [ "$(uname -s)" = Darwin ]; then
#    curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/darwin/amd64/kubectl"
#else
#    curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
#fi

date "+%F %T  downloading kubectl"
curl -sSLO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/$platform/amd64/kubectl"

date "+%F %T  downloaded kubectl"
date "+%F %T  chmod'ing and moving to ~/bin"
chmod +x kubectl
mkdir -pv ~/bin
unalias mv &>/dev/null || :
mv -vf kubectl ~/bin/
echo
~/bin/kubectl version --client


# =======================================================
# https://cert-manager.io/docs/usage/kubectl-plugin/

echo
echo
kubectl_cert_manager="kubectl-cert_manager"
date "+%F %T  downloading kubectl cert-manager plugin"
curl -sSLo kubectl-cert-manager.tar.gz "https://github.com/jetstack/cert-manager/releases/download/v$cert_manager_version/kubectl-cert_manager-$platform-amd64.tar.gz"
date "+%F %T  downloaded kubectl cert-manager plugin"
tar xzf kubectl-cert-manager.tar.gz
date "+%F %T  chmod'ing and moving to ~/bin"
chmod +x "$kubectl_cert_manager"
mv -vf "$kubectl_cert_manager" ~/bin/

echo
~/bin/"$kubectl_cert_manager" version
