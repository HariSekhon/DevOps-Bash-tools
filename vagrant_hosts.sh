#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-15 12:50:08 +0100 (Sat, 15 Aug 2020)
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
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Quick script to parse a given Vagrantfile and emit an /etc/hosts format output, eg:

172.16.0.2 kube1.local kube1
172.16.0.3 kube2.local kube2

Tested on vagrant/k8s/Vagrantfile
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
else
    usage "Vagrantfile not specified and no Vagrantfile found in \$PWD"
fi

grep -A 20 config.vm.define "$Vagrantfile" |
grep -e config.vm.define \
     -e '^[[:space:]]*config.vm.network.*private_network.*ip' |
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
