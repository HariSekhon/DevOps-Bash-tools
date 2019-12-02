#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-12-02 15:06:35 +0000 (Mon, 02 Dec 2019)
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
    echo "
Simple script to decommission an Elasticsearch node from the cluster

Defaults to connecting to a Elasticsearch via node localhost:9200
set \$ELASTICSEARCH_HOST and \$ELASTICSEARCH_PORT to override this
set \$ELASTICSEARCH_SSL to any value to enable SSL (ignores ssl validation as this is usually self-signed)
set \$ELASTICSEARCH_OPTS='-u : --negotiate' to use Kerberos ticket in local environment

${0##*/} <node_ip>

eg. ${0##*/} 192.168.1.23
"
    exit 3
}

if [ $# -ne 1 ]; then
    usage
fi

if [[ "$1" =~ -.* ]]; then
    usage
fi

node_ip="$1"
host="${ELASTICSEARCH_HOST:-localhost}"
port="${ELASTICSEARCH_PORT:-9200}"
http=http
if [ -n "${ELASTICSEARCH_SSL:-}" ]; then
    http=https
fi
curl_opts="${ELASTICSEARCH_OPTS:-}"

# want curl opts split
# shellcheck disable=SC2086
if curl -X PUT -k $curl_opts
    "$http://$host:$port/_cluster/settings" \
     -H 'Content-Type: application/json' \
     -d "{ \"transient\" :{ \"cluster.routing.allocation.exclude._ip\" : \"$node_ip\" } }"; then
    printf "\nSuccess. Now wait for background replication to migrate shards off node %s \n" "$1"
else
    printf "\nFailed\n"
fi
