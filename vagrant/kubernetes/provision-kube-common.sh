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

bash_tools="/bash"

# shellcheck disable=SC1090
source "$bash_tools/lib/utils.sh"

section "Running Vagrant Shell Provisioner Script - Kubernetes Common"

pushd /vagrant

"$bash_tools/install_packages_if_absent.sh" docker.io

systemctl enable docker.service
systemctl start docker.service

echo "deb  http://apt.kubernetes.io/  kubernetes-xenial  main" | "$bash_tools/bin/grep_or_append.sh" /etc/apt/sources.list.d/kubernetes.list

curl -sS https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

if ! dpkg -s kubeadm kubelet kubectl &>/dev/null; then
    /bash/install_packages_if_absent.sh \
        kubeadm=1.18.1-00 \
        kubelet=1.18.1-00 \
        kubectl=1.18.1-00

    apt-mark hold \
        kubelet \
        kubeadm \
        kubectl
fi

#source <(kubectl completion bash)
timestamp "adding bash completion for kubectl:"
echo "source <(kubectl completion bash)" | "$bash_tools/bin/grep_or_append.sh" ~/.bashrc
echo >&2

if ! [ -d /templates ] &&
   [ -d /github/perl-tools/templates ]; then
    ln -sv -- /github/perl-tools/templates /
fi

popd
