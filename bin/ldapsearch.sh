#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-02-01 16:49:45 +0000 (Fri, 01 Feb 2019)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# USAGE: (will default to your $USER account, infer domain base and prompt for password)
#
#  ./ldapsearch.sh <search_query>
#
# to test a different account, eg. a service bind account, do
#
#  LDAP_USER=<dn_or_email> LDAP_PASSWORD=<password> ./ldapsearch.sh <search_query>


set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

server="${LDAP_SERVER:-localhost}"

uri="ldap://$server"
if [ "${LDAP_SSL:-}" = 1 ]; then
    uri="ldaps://$server"
fi

# only works on Linux, not Mac
#domain="${DOMAIN:-$(hostname -d)}"
domain="${DOMAIN:-$(hostname -f | sed 's/^[^`.]*\.//')}"

#base_dn="${LDAP_BASE_DN:-dc=$(sed 's/\./,dc=/g' <<< "$domain")}"
base_dn="${LDAP_BASE_DN:-dc=${domain//./,dc=}}"

user="${LDAP_USER:-$USER@$domain}"

#set +x
PASS="${LDAP_PASSWORD:-${PASSWORD:-${PASS:-}}}"
# checks later for Kerberos first, otherwise sets ldapearch -W switch to prompt which is safer
#if [ -z "${PASS:-}" ]; then
#    pass
#fi

# shellcheck disable=SC2120
usage(){
    if [ -n "$*" ]; then
        echo "$@" >&2
        echo >&2
    fi
    # multiple ${0##*/} inside here document causes usage to not be rendered, must be a bash bug
    script="${0##*/}"
    cat >&2 <<EOF

Queries ldap easily using ldapsearch by inferring many common parameters to remove tediousness

Usually only requires setting one or two environment variables, eg. in .bashrc for fast and easy future ldapsearch queries, useful for systems administrators often doing ldap searches or those of use who forget these switches even after over a decade of using ldapsearch

\$LDAP_SERVER - defaults to localhost. This and \$LDAP_SSL are probably the minimum you need to set
\$LDAP_SSL - optional, enables SSL

\$LDAP_BASE_DN - infers from local host's domain portion of FQDN (or \$DOMAIN if set)

\$LDAP_USER - defaults to using \$USER@\$DOMAIN. \$USER is usually set, \$DOMAIN is found from 'hostname -f'
\$LDAP_PASSWORD / \$PASSWORD - prompts if not found


Caveat:

  $script <dn> - DN based search will not work with ldapsearch - you must use the DN as the \$LDAP_BASE_DN instead of search filter


usage: $script <ldap_filter> [<attribute_filter>]


EOF
    exit 3
}

for x in "$@"; do
    # shellcheck disable=SC2119
    case "$x" in
    -h|--help)  usage
                ;;
    esac
done

if [ "${LDAP_KRB5:-}" = 1 ]; then
    auth_opts="-Y GSSAPI"
else
    auth_opts="-x -D $user"
    if [ -n "${PASS:-}" ]; then
        auth_opts="$auth_opts -w $PASS"
    else
        auth_opts="$auth_opts -W"
    fi
fi

if [ -n "${DEBUG:-}" ]; then
    echo
    # shellcheck disable=SC2001
    sed "s/-w[[:space:]]\\{1,\\}[^[:space:]]\\{1,\\}/-w '...'/" <<< "## ldapsearch -H '$uri' -b '$base_dn' $auth_opts '$*'"
fi
# shellcheck disable=SC2086
ldapsearch -H "$uri" -b "$base_dn" -o ldif-wrap=no $auth_opts "$@"
