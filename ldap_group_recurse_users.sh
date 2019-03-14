#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-03-14 19:08:01 +0000 (Thu, 14 Mar 2019)
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

usage(){
    if [ -n "$*" ]; then
        echo "$@"
        echo
    fi
    cat <<EOF

Recurses AD LDAP for all users which are members of a given group DN

Dumps LDAP user objects, follows group nesting

Uses Microsoft Active Directory LDAP extension, so is not portable to other LDAP servers

See the python version in the DevOps Python Tools repo for a more generalized version with nicer control and output

https://github.com/harisekhon/devops-python-tools


usage: ${0##*/} <group_dn> [<attribute_filter>]


EOF
    exit 3
}

for x in $@; do
    case $x in
    -h|--help)  usage
                ;;
           -*)  usage "unknown argument: $x"
                ;;
    esac
done

if [ $# -lt 1 ]; then
    usage "no group DN given"
fi

group_dn="$1"
shift

"$srcdir/ldapsearch.sh" "(&(objectClass=user)(member:1.2.840.113556.1.4.1941:=$group_dn))" $@
