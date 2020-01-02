#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-01-02 16:19:20 +0000 (Thu, 02 Jan 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Script to fetch Impala queries from Cloudera Manager
#
# combine with jq commands to extract just the list of SQL queries from the rich json output
#
# ./cloudera_manager_impala_queries.sh | jq -r '.queries[].statement'

# Raw JSON output example:
#
# {
#   "queries" : [ {
#     "queryId" : "1234f56ae78ff9:123d45f000000000",
#     "statement" : "select count(*) from myDB.myTable -- somecomment",  # might be just GET_SCHEMAS / GET_TABLES / USE `myDB` / USE myDB
#     "queryType" : "QUERY",
#     "queryState" : "FINISHED",
#     "startTime" : "2020-01-02T15:03:44.746Z",
#     "endTime" : "2020-01-02T15:33:13.886Z",
#     "rowsProduced" : null,
#     "attributes" : {
#       "thread_network_receive_wait_time" : "21347",
#       "hdfs_average_scan_range" : "3898.6171543326227",
#       "bytes_streamed" : "224",
#       "memory_spilled" : "0",
#       "hdfs_bytes_read_short_circuit" : "221312800",
#       "hdfs_bytes_read_from_cache" : "0",
#       "hdfs_bytes_read" : "221312800",
#       "query_status" : "OK",
#       "hdfs_scanner_average_bytes_read_per_second" : "5.663271900927363E7",
#       "oom" : "false",
#       "planning_wait_time_percentage" : "0",
#       "admission_wait" : "0",
#       "connected_user" : "hue",
#       "stats_missing" : "false",
#       "planning_wait_time" : "147",
#       "memory_aggregate_peak" : "4781060.0",
#       "client_fetch_wait_time_percentage" : "99",
#       "memory_per_node_peak_node" : "<fqdn>:22000",
#       "session_type" : "HIVESERVER2",
#       "hdfs_bytes_read_remote" : "0",
#       "estimated_per_node_peak_memory" : "10485760",
#       "hdfs_bytes_read_local_percentage" : "100",
#       "hdfs_bytes_read_from_cache_percentage" : "0",
#       "client_fetch_wait_time" : "1747483",
#       "delegated_user" : "hari",
#       "file_formats" : "PARQUET/NONE",
#       "admission_result" : "Admitted immediately",
#       "pool" : "root.hari_dot_sekhon",
#       "session_id" : "12345f9f0eb1b323:18e29b3cb123456d",
#       "hdfs_bytes_read_remote_percentage" : "0",
#       "hdfs_bytes_read_short_circuit_percentage" : "100",
#       "memory_accrual" : "3.1359538E7",
#       "impala_version" : "impalad version 2.7.0-cdh5.10.0 RELEASE (build 785a073cd07e2540d521ecebb8b38161ccbd2aa2)",
#       "network_address" : "<ip_x.x.x.x>:33447",
#       "hdfs_bytes_read_local" : "221312800",
#       "memory_per_node_peak" : "1520435.2",
#       "thread_network_send_wait_time" : "0",
#       "thread_storage_wait_time" : "1511999"
#     },
# 	...
#   } ],
#   "warnings" : [ "Impala query scan limit reached. Last end time considered is 2019-12-28T12:29:48.471Z" ]
# }


set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -z "${CLOUDERA_MANAGER:-}" ]; then
    read -r -p 'Enter Clouder Manager host URL: ' CLOUDERA_MANAGER
fi

if [ -n "${CLOUDERA_MANAGER_SSL:-}" ]; then
    CLOUDERA_MANAGER="https://${CLOUDERA_MANAGER#*://}"
fi

# seems to work on CM / CDH 5.10.0 even when cluster is set to 'blah' but probably shouldn't rely on that
if [ -z "${CLOUDERA_CLUSTER:-}" ]; then
    read -r -p 'Enter Clouder Manager Cluster name: ' CLOUDERA_CLUSTER
fi

# 2020-01-02T16%3A17%3A57.514Z
# url encoding : => %3A seems to be done automatically by curl so not bothering to urlencode here
now_timestamp="$(date '+%Y-%m-%dT%H:%M:%S.000Z')"

echo "fetching queryies up to now:  $now_timestamp" >&2

"$srcdir/curl_auth.sh" "$CLOUDERA_MANAGER/api/v7/clusters/$CLOUDERA_CLUSTER/services/impala/impalaQueries?from=1970-01-01T00%3A00%3A00.000Z&to=$now_timestamp&filter="
