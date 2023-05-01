#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: vagrant/kubernetes/Vagrantfile
#
#  Author: Hari Sekhon
#  Date: 2020-08-15 12:50:08 +0100 (Sat, 15 Aug 2020)
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

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Quick script to parse a given Vagrantfile and emit an /etc/hosts format output, eg:

172.16.0.2 kube1.local kube1
172.16.0.3 kube2.local kube2

Vagrantfile can be given as first arg, otherwise checks for \$PWD/Vagrantfile or /vagrant/Vagrantfile for convenience

Tested on vagrant/kubernetes/Vagrantfile in this repo and used as part of provision scripts
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<Vagrantfile>"

help_usage "$@"

#min_args 1 "$@"

if [ $# -gt 0 ]; then
    Vagrantfile="$1"
elif [ -f Vagrantfile ]; then
    Vagrantfile=Vagrantfile
elif [ -f /vagrant/Vagrantfile ]; then
    # auto-detect when running inside a Vagrant VM
    Vagrantfile=/vagrant/Vagrantfile
else
    usage "Vagrantfile not specified and no Vagrantfile found in \$PWD or /vagrant/"
fi

sed 's/#.*//; /^[[:space:]]*$/d' "$Vagrantfile" |
grep -A 20 '^[[:space:]]*config.vm.define' |
grep -e '^[[:space:]]*config.vm.define' \
     -e '^[[:space:]]*config.vm.network.*private_network.*ip' |
grep -v -e "^--" -e "default_hostname" |
sed '
    s/ do .*//;
    s/config.vm.[[:alnum:]]*//;
    s/private_network//g;
    s/[^[:alnum:][:space:].]//g;
    s/[[:space:]]ip[[:space:]]//
' |
while read -r host; do
    read -r ip
    echo "$ip $host.local $host"
done
