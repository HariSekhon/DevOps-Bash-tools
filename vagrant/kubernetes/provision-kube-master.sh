#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-14 13:16:04 +0100 (Fri, 14 Aug 2020)
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

# has to be before brace to set up logging path and logfile name
mkdir -pv /vagrant/logs
name="${0##*/}"
log="/vagrant/logs/${name%.sh}.log"

{

bash_tools="/bash"

# shellcheck source=provision-kube-common.sh
. "/vagrant/provision-kube-common.sh"

section "Running Vagrant Shell Provisioner Script - Kubernetes Master"

kubeadm_join="/vagrant/kubeadm_join.sh"

pushd /vagrant

flannel_yml=kube-flannel.yml
calico_yaml=calico.yaml
weavenet_yaml=weavenet.yaml

# XXX: one-line CNI deployment change right here :-)
selected_cni="$calico_yaml"

# should already be in the vagrant dir
if [ "$selected_cni" = "$flannel_yml" ]; then
    if ! [ -s "$flannel_yml" ]; then
        timestamp "Fetching $flannel_yml:"
        wget -O "$flannel_yml" https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
    fi
elif [ "$selected_cni" = "$calico_yaml" ]; then
    if ! [ -s "$calico_yaml" ]; then
        timestamp "Fetching $calico_yaml:"
        wget -O "$calico_yaml" https://docs.projectcalico.org/manifests/calico.yaml
    fi
elif [ "$selected_cni" = "$weavenet_yaml" ]; then
    if ! [ -s "$weavenet_yaml" ]; then
        timestamp "Fetching $weavenet_yaml:"
        #wget -O "weave.sh https://git.io/weave
        wget -O "$weavenet_yaml" "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
    fi
else
    echo "Selected CNI '$selected_cni' doesn't match one of: $flannel_yml, $calico_yaml, $weavenet_yaml"
    exit 1
fi

echo >&2

if ! netstat -lnt | grep -q :10248; then
    timestamp "Bootstrapping kubernetes master:"
    echo >&2
    # remove stale old generated join script so worker(s) awaits new one
    rm -fv -- "$kubeadm_join"
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
        cp -vf -- /etc/kubernetes/admin.conf "$kube_config"
    fi
done
chown -v "$(id -u):$(id -g)" ~/.kube/config
chown -v vagrant:vagrant /home/vagrant/.kube/config
cp -vf -- ~/.kube/config /vagrant/.kube/config
echo >&2

timestamp "Applying CNI $selected_cni:"
kubectl apply -f "$selected_cni"

echo >&2

timestamp "Kubernetes Node Taints:"
kubectl describe nodes | grep -i -e '^Name:' -e '^Taints:'

echo >&2

timestamp "untainting master node for pod scheduling"
kubectl taint nodes --all node-role.kubernetes.io/master- || :

echo >&2

kubectl describe nodes | grep -i -e '^Name:' -e '^Taints:'

echo >&2

kubectl taint nodes --all node.kubernetes.io/not-ready- || :

echo >&2

timestamp "Kubernetes Nodes:"
kubectl get nodes

echo >&2

timestamp "(re)generating $kubeadm_join for workers to use"
"$bash_tools/kubeadm_join_cmd.sh" > "$kubeadm_join"
chmod +x "$kubeadm_join"

} 2>&1 | tee -a "$log"
