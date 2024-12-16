#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-12-23 12:14:19 +0000 (Thu, 23 Dec 2021)
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
. "$srcdir/lib/aws.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Searches CloudWatch Logs for AWS Batch job submit requests in the last N hours to find who is running large expensive jobs

Defaults to finding logs in the last 24 hours but can optionally take an hours argument to search the last N hours

Example:

    ${0##*/}

    ${0##*/} 48     # 48 hours ago to present

    ${0##*/} 24 3   # 24 hours ago to 3 hours ago

    # explicitly calculated dates in millisecond epochs (hence the suffixed 000), using standard AWS CLI options (now you see why I default to the simple hours ago optional args)
    ${0##*/} --start-time \"\$(date +%s --date='2021-12-21')000\" --end-time \"\$(date +%s --date='2021-12-23')000\"


Output Format:

<timestamp>     <job_id>    <user>    <job_name>
eg.
2021-12-22T19:28:57Z    12a345b6-c789-0de1-f2a3-4b567cdef8ab    hari@domain.com       my_job_1
2021-12-22T20:22:17Z    123ab4cd-e5f6-789a-b012-34c5d67e8f90    MyBatchRole/1ab2c34567890123d45e678f901a2b34  my_report_postprocess


$usage_aws_cli_jq_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<hours_ago_start> <hours_ago_end> <aws_cli_options>]"

help_usage "$@"

#min_args 1 "$@"

"$srcdir/aws_logs.sh" "$@" \
                      --log-group-name aws-controltower/CloudTrailLogs \
                      --filter-pattern '{ ($.eventSource = "batch.amazonaws.com") && ($.eventName = "SubmitJob") }' |
jq -r '.events[].message' |
jq_debug_pipe_dump_slurp |
jq -r -s '.[] |
          [
            .eventTime,
            .responseElements.jobId,
            ( .userIdentity.arn | sub("arn:aws:sts::\\d+:assumed-role/"; "") | sub("AWSReservedSSO_\\w+/"; "") ),
            .responseElements.jobName
          ] |
          @tsv'
