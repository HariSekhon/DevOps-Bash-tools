#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-14 13:16:04 +0100 (Fri, 14 Aug 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

mkdir -pv /vagrant/logs

{

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

bash_tools="/bash-tools"

# shellcheck disable=SC1090
source "$bash_tools/lib/utils.sh"

section "Running Vagrant Shell Provisioner Script - Kubernetes"

# remove stale old generated join script so kube2 awaits new one
rm -fv /vagrant/k8s_join.sh

pushd /vagrant

apt-get install -y docker.io

systemctl enable docker.service
systemctl start docker.service

echo "deb  http://apt.kubernetes.io/  kubernetes-xenial  main" >> /etc/apt/sources.list.d/kubernetes.list

curl -sS https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

apt-get update

apt-get install -y \
    kubeadm=1.18.1-00 \
    kubelet=1.18.1-00 \
    kubectl=1.18.1-00

apt-mark hold \
    kubelet \
    kubeadm \
    kubectl

#source <(kubectl completion bash)
timestamp "adding bash completion for kubectl:"
echo "source <(kubectl completion bash)" | "$bash_tools/grep_or_append.sh" ~/.bashrc
echo >&2

} 2>&1 | tee -a /vagrant/logs/provision-kube.log
