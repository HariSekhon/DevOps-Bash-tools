#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-02-25 23:53:53 +0000 (Sun, 25 Feb 2024)
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
Creates a Solr Collection via the Solr API if it does not already exist

Uses the adjacent script solr_api.sh - see it for required environment variables and authentication

Assume a config of the same name already exists in ZooKeeper

Set environment variables

NUM_SHARDS              defaults to 3
REPLICATION_FACTOR      defaults to 3
NUM_SHARDS_PER_NODE     defaults to 9

See Also

    Solr CLI - https://github.com/HariSekhon/DevOps-Perl-tools
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<collection_name> [<curl_options>]"

help_usage "$@"

min_args 1 "$@"

collection="$1"
shift || :

NUM_SHARDS="${NUM_SHARDS:-3}"
MAX_SHARDS_PER_NODE="${MAX_SHARDS_PER_NODE:-9}"
REPLICATION_FACTOR="${REPLICATION_FACTOR:-3}"

timestamp "Checking if collection '$collection' already exists"
if "$srcdir/solr_collection_check_exists.sh" "$collection"; then
    timestamp "Skipping create"
else
    "$srcdir/solr_api.sh" "/solr/admin/collections?action=CREATE&name=$collection&numShards=$NUM_SHARDS&maxShardsPerNode=$MAX_SHARDS_PER_NODE&replicationFactor=$REPLICATION_FACTOR&wt=xml&collection.configName=$collection&autoAddReplicas=true"
fi
