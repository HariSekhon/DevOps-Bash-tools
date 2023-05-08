#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-01-23 15:08:10 +0000 (Thu, 23 Jan 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Script to fetch Yarn apps from Cloudera Manager
#
# combine with jq commands to extract just the list of SQL queries from the rich json output
#
# ./cloudera_manager_yarn_apps.sh | jq -r '.applications[]'

# Tested on Cloudera Enterprise 5.10

# Raw JSON output example:
#
# {
#   "applications" : [ {
#     "applicationId" : "application_1571433934948_123456",
#     "name" : "HdfsReplication",
#     "startTime" : "2020-01-19T18:17:52.257Z",
#     "user" : "hive",
#     "pool" : "root.users.hive",
#     "state" : "RUNNING",
#     "progress" : 95.0,
#     "attributes" : {
#       "failed_map_attempts" : "0",
#       "failed_reduce_attempts" : "0",
#       "failed_tasks_attempts" : "0",
#       "killed_map_attempts" : "0",
#       "killed_reduce_attempts" : "0",
#       "killed_tasks_attempts" : "0",
#       "map_progress" : "100.0",
#       "maps_completed" : "20",
#       "maps_pending" : "0",
#       "maps_running" : "0",
#       "maps_total" : "20",
#       "new_map_attempts" : "0",
#       "new_reduce_attempts" : "0",
#       "new_tasks_attempts" : "0",
#       "reduce_progress" : "100.0",
#       "reduces_completed" : "0",
#       "reduces_pending" : "0",
#       "reduces_running" : "1",
#       "reduces_total" : "1",
#       "running_application_info_retrieval_time" : "8.97",
#       "running_map_attempts" : "0",
#       "running_reduce_attempts" : "1",
#       "running_tasks_attempts" : "1",
#       "successful_map_attempts" : "20",
#       "successful_reduce_attempts" : "0",
#       "successful_tasks_attempts" : "20"
#       "tasks_completed" : "20",
#       "tasks_pending" : "0",
#       "tasks_running" : "1",
#       "total_task_num" : "21",
#       "tracking_url" : "https://<fqdn>:8090/proxy/application_1571433934948_123456/",
#       "uberized" : "false",
#     },
#     "mr2AppInformation" : { }
#   }, {
#     "applicationId" : "application_1571433934948_123456",
#     "name" : "oozie:launcher:T=shell:W=blah/blah:A=myuser-node:ID=0009168-200118163518563-oozie-oozi-W",
#     "startTime" : "2020-01-23T14:40:48.442Z",
#     "user" : "myuser",
#     "pool" : "root.stream",
#     "state" : "RUNNING",
#     "progress" : 95.0,
#     "attributes" : {
#       "failed_map_attempts" : "0",
#       "failed_reduce_attempts" : "0",
#       "failed_tasks_attempts" : "0",
#       "killed_map_attempts" : "0",
#       "killed_reduce_attempts" : "0",
#       "killed_tasks_attempts" : "0",
#       "map_progress" : "100.0",
#       "maps_completed" : "0",
#       "maps_pending" : "0",
#       "maps_running" : "1",
#       "maps_total" : "1",
#       "new_map_attempts" : "0",
#       "new_reduce_attempts" : "0",
#       "new_tasks_attempts" : "0",
#       "reduce_progress" : "0.0",
#       "reduces_completed" : "0",
#       "reduces_pending" : "0",
#       "reduces_running" : "0",
#       "reduces_total" : "0",
#       "running_application_info_retrieval_time" : "0.008",
#       "running_map_attempts" : "1",
#       "running_reduce_attempts" : "0",
#       "running_tasks_attempts" : "1",
#       "successful_map_attempts" : "0",
#       "successful_reduce_attempts" : "0",
#       "successful_tasks_attempts" : "0"
#       "tasks_completed" : "0",
#       "tasks_pending" : "0",
#       "tasks_running" : "1",
#       "total_task_num" : "1",
#       "tracking_url" : "https://<fqdn>:8090/proxy/application_1571433934948_123456/",
#       "uberized" : "false",
#     },
#     "mr2AppInformation" : { }
#   },
#   ...
#  {
#     "applicationId" : "application_1571433934948_123456",
#     "name" : "my_biz_process.py",
#     "startTime" : "2020-01-23T09:26:56.878Z",
#     "endTime" : "2020-01-23T09:29:50.705Z",
#     "user" : "myETLuser",
#     "pool" : "root.users.myETLuser",
#     "state" : "FINISHED",
#     "progress" : 100.0,
#     "attributes" : { },
#     "mr2AppInformation" : { }
#   } ],
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

"$srcdir/cloudera_manager_api.sh" "/clusters/$CLOUDERA_CLUSTER/services/yarn/yarnApplications?from=1970-01-01T00%3A00%3A00.000Z&to=$now_timestamp&filter="
