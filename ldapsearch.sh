#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-02-01 16:49:45 +0000 (Fri, 01 Feb 2019)
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

server="${LDAP_SERVER:-localhost}"

uri="ldap://$server"
if [ "${LDAP_SSL:-}" = 1 ]; then
    uri="ldaps://$server"
fi

domain="$(hostname -f | sed 's/^[^`.]*\.//')"

base_dn="${LDAP_BASE_DN:-dc=$(sed 's/\./,dc=/g' <<< "$domain")}"

user="${LDAP_USER:-$USER@$domain}"

set +x
PASS="${LDAP_PASSWORD:-${PASSWORD:-${PASS:-}}}"
if [ -z "${PASS:-}" ]; then
    read -s -p "password: " PASS
fi

if [ "${LDAP_KRB5:-}" = 1 ]; then
    auth_opts="-Y GSSAPI"
else
    auth_opts="-x -D $user -w $PASS"
fi

if [ "${DEBUG:-}" = 1 ]; then
    echo
    sed "s/-w[[:space:]]\+[^[:space:]]\+/-w '...'/" <<< "## ldapsearch -H '$uri' -b '$base_dn' $auth_opts '$@'"
fi
ldapsearch -H "$uri" -b "$base_dn" $auth_opts "$@"
