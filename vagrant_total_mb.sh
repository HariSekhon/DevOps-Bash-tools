#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-23 23:08:43 +0100 (Sun, 23 Aug 2020)
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

usage(){
    cat <<EOF
Calculates the total combined RAM in MB allocated to all VMs in a Vagrantfile

Can take one or more Vagrantfiles given as arguments, otherwise tries to read a Vagrantfile in the \$PWD
EOF
    exit 3
}

for arg; do
    case "$arg" in
        -*) usage
            ;;
    esac
done

grep -E '^[^#]+\.memory' "${@:-Vagrantfile}" |
sed 's/.*=[[:space:]]*//' |
grep -E '^[[:digit:]]+(\.[[:digit:]]+)?$' |
tr '\n' '+' |
sed 's/+$//' |
bc -l
