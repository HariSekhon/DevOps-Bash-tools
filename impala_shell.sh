#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-12-10 11:33:52 +0000 (Tue, 10 Dec 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Script to more easily connect to HiveServer2 without having to specify the big connection string

# If you get an error such as:
#
# Error connecting: TTransportException, TSocket read 0 bytes
#
# then check if you need to add --ssl to the command line (or export IMPALA_SSL=1 to do this automatically, eg. put in .bashrc or similar)

# useful options for scripting:
#
#   -q --query
#   -B --delimited
#   --output_delimiter=\t   # default
#
# list all databases:
#
#   ./impala_shell.sh -Bq 'show databases' | awk '{print $1}'
#
# list all tables in all databases:
#
#   ./impala_shell.sh -Bq 'show databases' | while read db rest; do ./impala_shell.sh -Bq "use $db; show tables" | sed "s/^/$db./"; done

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

opts=""

if grep -A 1 hadoop.security.authentication /etc/hadoop/conf/core-site.xml  | grep -q kerberos; then
    opts="$opts -k"
fi

if [ -n "${IMPALA_SSL:-}" ]; then
    opts="$opts --ssl"
fi

topology_map="/etc/hadoop/conf/topology.map"

if [ -n "${IMPALA_HOST:-}" ]; then
    impalad="$IMPALA_HOST"
elif [ -f "$topology_map" ]; then
    # or alternatively use HAProxy config for load balanced impala clusters - see https://github.com/harisekhon/haproxy-configs
    #echo "picking random impala from hadoop topology map" >&2
    impalad="$(awk -F'"' '/<node name="[A-Za-z]/{print $2}' "$topology_map" | grep -v -e name -e master -e control | shuf -n 1)"
else
    impalad="$(hostname -f)"
    #echo "IMPALA_HOST not set and topology map '$topology_map' not found, defaulting to local host $impalad"
fi

# split opts
# shellcheck disable=SC2086
impala-shell $opts -i "$impalad" "$@"
