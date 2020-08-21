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

name="${0##*/}"
name="${name%.sh}"

{

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

bash_tools="/bash-tools"

# shellcheck disable=SC1090
source "$bash_tools/lib/utils.sh"

section "Running Vagrant Shell Provisioner Script - Kube2"

echo >&2

pushd /vagrant

kubeadm_join="/vagrant/kubeadm_join.sh"

if ! netstat -lnt | grep -q :10248; then
    timestamp "Bootstrapping kubernetes worker:"
    echo >&2

    # happens after kube1 anyway
    #timestamp "waiting for 15 secs to give kube1 time to provision"
    #sleep 15

    timestamp "Waiting for kube1 to bootstrap and generate kubectl join command at $kubeadm_join"
    SECONDS=0
    while ! [ -f "$kubeadm_join" ]; do
        if [ $SECONDS -gt 600 ]; then
            timestamp "ERROR: max wait time for $kubeadm_join to appear exceeded, aborting worker node join. Check provisioner run on kube1 has generated $kubeadm_join or re-run provisioner"
            exit 1
        fi
        sleep 1
    done
    echo >&2

    # doesn't error out if already joined
    timestamp "Running $kubeadm_join"
    chmod +x "$kubeadm_join"
    "$kubeadm_join"

    echo >&2
fi

timestamp "Configuring kubectl:"
mkdir -pv ~/.kube /home/vagrant/.kube
for kube_config in ~/.kube/config /home/vagrant/.kube/config; do
    if ! [ -f "$kube_config" ]; then
        cp -vf /vagrant/.kube/config "$kube_config"
    fi
done
chown -v "$(id -u):$(id -g)" ~/.kube/config
chown -v vagrant:vagrant /home/vagrant/.kube/config
echo >&2

timestamp "Kubernetes Nodes:"
kubectl get nodes

} 2>&1 | tee -a "/vagrant/logs/$name.log"
