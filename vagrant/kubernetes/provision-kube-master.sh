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

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

mkdir -pv /vagrant/logs

name="${0##*/}"
name="${name%.sh}"

{

bash_tools="/bash-tools"

# shellcheck disable=SC1090
source "$bash_tools/lib/utils.sh"

section "Running Vagrant Shell Provisioner Script - Kube1"

kubeadm_join="/vagrant/kubeadm_join.sh"

pushd /vagrant

# should already be in the vagrant dir
if ! [ -f calico.yaml ]; then
    timestamp "Fetching calico.yaml:"
    wget https://docs.projectcalico.org/manifests/calico.yaml
fi

echo >&2

if ! netstat -lnt | grep -q :10248; then
    timestamp "Bootstrapping kubernetes master:"
    echo >&2
    # remove stale old generated join script so kube2 awaits new one
    rm -fv "$kubeadm_join"
    echo >&2
    # kubeadm-config.yml is in vagrant dir mounted at /vagrant
    kubeadm init --node-name "$(hostname -f)" --config=kubeadm-config.yaml --upload-certs | tee /vagrant/logs/kubeadm-init.out # save output for review
    echo >&2
fi

kubeadm token list

echo >&2

timestamp "Configuring kubectl:"
mkdir -pv ~/.kube /home/vagrant/.kube /vagrant/.kube
for kube_config in ~/.kube/config /home/vagrant/.kube/config; do
    if ! [ -f "$kube_config" ]; then
        cp -vf /etc/kubernetes/admin.conf "$kube_config"
    fi
done
chown -v "$(id -u):$(id -g)" ~/.kube/config
chown -v vagrant:vagrant /home/vagrant/.kube/config
cp -vf ~/.kube/config /vagrant/.kube/config
echo >&2

timestamp "Applying calico.yaml:"
kubectl apply -f calico.yaml

echo >&2

timestamp "K8S Nodes:"
kubectl get nodes

echo >&2

kubectl taint nodes --all node-role.kubernetes.io/master- || :

echo >&2

kubectl get nodes

echo >&2

kubectl taint nodes --all node.kubernetes.io/not-ready- || :

echo >&2

kubectl get nodes

echo >&2

timestamp "(re)generating $kubeadm_join for kube2 to use"
"$bash_tools/kubernetes_join_cmd.sh" > "$kubeadm_join"
chmod +x "$kubeadm_join"

} 2>&1 | tee -a "/vagrant/logs/$name.log"
