#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-12-02 15:06:35 +0000 (Mon, 02 Dec 2019)
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

usage(){
    echo "
Simple script to trigger a background decommission of an Elasticsearch node from the local cluster

Defaults to connecting to the Elasticsearch cluster via the node localhost:9200
set \$ELASTICSEARCH_HOST and \$ELASTICSEARCH_PORT to override this
set \$ELASTICSEARCH_SSL to any value to enable SSL (ignores ssl validation as this is usually self-signed)

${0##*/} <node_ip> [curl_options]

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

# could make this better by checking octets etc like my Python / Perl libraries
# but don't want this script to get too heavy with dependencies
if ! [[ "$node_ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    echo "Invalid node IP given: $node_ip"
    exit 1
fi

# want curl opts split
# shellcheck disable=SC2086
if curl -X PUT -k "${@:2}"
    "$http://$host:$port/_cluster/settings" \
     -H 'Content-Type: application/json' \
     -d "{ \"transient\" :{ \"cluster.routing.allocation.exclude._ip\" : \"$node_ip\" } }"; then
    printf '\nSuccess. Now wait for background replication to migrate shards off node %s \n' "$1"
else
    printf '\nFailed\n'
fi
