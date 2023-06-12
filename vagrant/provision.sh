#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-14 13:16:04 +0100 (Fri, 14 Aug 2020)
#  (forked from private repo from 2013)
#  Original Date: 2013-03-18 16:38:04 +0000 (Mon, 18 Mar 2013)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

mkdir -pv /vagrant/logs

{

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
#srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash_tools="/github/bash-tools"

# shellcheck disable=SC1090,SC1091
source "$bash_tools/lib/utils.sh"

section "Running Vagrant Shell Provisioner Script - Base"

mkdir -p /root/.ssh
sed 's/#.*//; /^[[:space:]]*$/d' /home/vagrant/.ssh/authorized_keys |
while read -r line; do
    if ! [ -f /root/.ssh/authorized_keys ] ||
       ! grep -Fqx "$line" /root/.ssh/authorized_keys; then
        echo "adding SSH authorized key to /root/.ssh/authorized_keys: $line"
        echo "$line" >> /root/.ssh/authorized_keys
    fi
done

pushd "$bash_tools"
echo >&2

timestamp "stripping 127.0.1.1 from /etc/hosts to avoid hostname resolve clash"
sed -ibak '/127.0.1.1/d' /etc/hosts

timestamp "adding /etc/hosts entries from Vagrantfile"
"$bash_tools/vagrant/vagrant_hosts.sh" /vagrant/Vagrantfile | "$bash_tools/bin/grep_or_append.sh" /etc/hosts

timestamp "disabling swap"
"$bash_tools/bin/disable_swap.sh"
echo >&2

timestamp "custom shell configuration and config linking as user '$USER':"
make link
echo >&2
# above links as root, let's link as vagrant too
if [ $EUID = 0 ] && id vagrant &>/dev/null; then
    timestamp "custom shell configuration and config linking as user 'vagrant':'"
    su - vagrant -c "pushd '$bash_tools'; make link"
fi

packages="vim bash-completion"

timestamp "installing: $packages"
#apt-get update
#apt-get install -y vim bash-completion

# want splitting
# shellcheck disable=SC2086
"$bash_tools/packages/install_packages_if_absent.sh" $packages

} 2>&1 | tee -a "/vagrant/logs/provision-$HOSTNAME.log"
