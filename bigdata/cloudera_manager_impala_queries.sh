#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-01-02 16:19:20 +0000 (Thu, 02 Jan 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Script to fetch Impala queries from Cloudera Manager
#
# combine with jq commands to extract just the list of SQL queries from the rich json output
#
# ./cloudera_manager_impala_queries.sh | jq -r '.queries[].statement'

# Tested on Cloudera Enterprise 5.10

# Raw JSON output example:
#
# {
#   "queries" : [ {
#     "queryId" : "1234f56ae78ff9:123d45f000000000",
#     "statement" : "select count(*) from myDB.myTable -- somecomment",  # might be just GET_SCHEMAS / GET_TABLES / USE myDB / DESCRIBE FORMATTED `myDB`.`myTable` / REFRESH myDB.myTable etc.
#     "queryType" : "QUERY",
#     "queryState" : "FINISHED",
#     "startTime" : "2020-01-02T15:03:44.746Z",
#     "endTime" : "2020-01-02T15:33:13.886Z",
#     "rowsProduced" : null,
#     "attributes" : {
#       "admission_result" : "Admitted immediately",
#       "admission_wait" : "0",
#       "bytes_streamed" : "224",
#       "client_fetch_wait_time" : "1747483",
#       "client_fetch_wait_time_percentage" : "99",
#       "connected_user" : "hue",
#       "delegated_user" : "hari",
#       "estimated_per_node_peak_memory" : "10485760",
#       "file_formats" : "PARQUET/NONE",
#       "hdfs_average_scan_range" : "3898.6171543326227",
#       "hdfs_bytes_read" : "221312800",
#       "hdfs_bytes_read_from_cache" : "0",
#       "hdfs_bytes_read_from_cache_percentage" : "0",
#       "hdfs_bytes_read_local" : "221312800",
#       "hdfs_bytes_read_local_percentage" : "100",
#       "hdfs_bytes_read_remote" : "0",
#       "hdfs_bytes_read_remote_percentage" : "0",
#       "hdfs_bytes_read_short_circuit" : "221312800",
#       "hdfs_bytes_read_short_circuit_percentage" : "100",
#       "hdfs_scanner_average_bytes_read_per_second" : "5.663271900927363E7",
#       "impala_version" : "impalad version 2.7.0-cdh5.10.0 RELEASE (build 785a073cd07e2540d521ecebb8b38161ccbd2aa2)",
#       "memory_accrual" : "3.1359538E7",
#       "memory_aggregate_peak" : "4781060.0",
#       "memory_per_node_peak" : "1520435.2",
#       "memory_per_node_peak_node" : "<fqdn>:22000",
#       "memory_spilled" : "0",
#       "network_address" : "<ip_x.x.x.x>:33447",
#       "oom" : "false",
#       "planning_wait_time" : "147",
#       "planning_wait_time_percentage" : "0",
#       "pool" : "root.hari_dot_sekhon",
#       "query_status" : "OK",
#       "session_id" : "12345f9f0eb1b323:18e29b3cb123456d",
#       "session_type" : "HIVESERVER2",
#       "stats_missing" : "false",
#       "thread_network_receive_wait_time" : "21347",
#       "thread_network_send_wait_time" : "0",
#       "thread_storage_wait_time" : "1511999"
#     },
#   }, {
#     "queryId" : "1b234f5cdf67890f:c1ad23e400000000",
#     "statement" : "USE myDB",
#     "queryType" : "DDL",
#     "queryState" : "FINISHED",
#     "startTime" : "2020-01-02T10:52:33.645Z",
#     "endTime" : "2020-01-02T10:52:33.883Z",
#     "rowsProduced" : null,
#     "attributes" : {
#       "admission_result" : "Unknown",
#       "client_fetch_wait_time" : "11",
#       "client_fetch_wait_time_percentage" : "5",
#       "connected_user" : "<user>@<domain>",
#       "ddl_type" : "USE",
#       "file_formats" : "",
#       "impala_version" : "impalad version 2.7.0-cdh5.10.0 RELEASE (build 785a073cd07e2540d521ecebb8b381)",
#       "network_address" : "<ip_x.x.x.x>:36528",
#       "oom" : "false",
#       "original_user" : "<user>@<domain>",
#       "planning_wait_time" : "203",
#       "planning_wait_time_percentage" : "85",
#       "query_status" : "OK",
#       "session_id" : "1234567d89e01f23:12b34567890d1faf",
#       "session_type" : "HIVESERVER2"
#       "stats_missing" : "false",
#     },
#     "user" : "<user>",
#     "coordinator" : {
#       "hostId" : "e12fc3c4-5678-9f01-2345-678de90123fe"
#     },
#     "detailsAvailable" : true,
#     "database" : "default",
#     "durationMillis" : 238
#   ...
#   } ],
#   "warnings" : [ "Impala query scan limit reached. Last end time considered is 2019-12-28T12:29:48.471Z" ]
# }


set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/utils.sh
. "$srcdir/lib/utils.sh"

# shellcheck source=lib/cloudera_manager.sh
. "$srcdir/lib/cloudera_manager.sh"

# defined in lib
# shellcheck disable=SC2154
timestamp "fetching queries up to now:  $now_timestamp"

"$srcdir/cloudera_manager_api.sh" "/clusters/$CLOUDERA_CLUSTER/services/impala/impalaQueries?from=1970-01-01T00%3A00%3A00.000Z&to=$now_timestamp&filter="
