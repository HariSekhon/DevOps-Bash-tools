#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-12-23 12:14:19 +0000 (Thu, 23 Dec 2021)
#
#  https://github.com/HariSekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "${BASH_SOURCE[0]}")"

# shellcheck disable=SC1090
. "$srcdir/lib/aws.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Searches CloudWatch Logs for AWS Batch job submit requests in the last N hours to find who is running large expensive jobs

Defaults to finding logs in the last 24 hours but can optionally take an hours argument to search the last N hours

Example:

    ${0##*/}

    ${0##*/} 48      # 48 hours ago to present

    ${0##*/} 24 12   # 24 hours ago to 12 hours ago


Output Format:

<timestamp>     <job_id>    <user>    <job_name>



$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<hours> <aws_cli_options>]"

help_usage "$@"

#min_args 1 "$@"

hours_ago_start=24
hours_ago_end=0

if [ -n "${1:-}" ] &&
   ! [[ "${1:-}" =~ ^- ]]; then
    hours_ago_start="$1"
    shift || :
fi

if [ -n "${1:-}" ] &&
   ! [[ "${1:-}" =~ ^- ]]; then
    hours_ago_end="$1"
    shift || :
fi

if ! [[ "$hours_ago_start" =~ ^[[:digit:]]+$ ]]; then
    usage "invalid value given for hours ago start argument, must be an integer"
fi

if ! [[ "$hours_ago_end" =~ ^[[:digit:]]+$ ]]; then
    usage "invalid value given for hours ago end argument, must be an integer"
fi


aws logs filter-log-events --log-group-name aws-controltower/CloudTrailLogs \
                           --start-time "$(date '+%s' --date="$hours_ago_start hours ago")000" \
                           --end-time "$(date '+%s' --date="$hours_ago_end hours ago")000" \
                           --filter-pattern '{ ($.eventSource = "batch.amazonaws.com") && ($.eventName = "SubmitJob") }' \
                           "$@" |
                           #--max-items 1 \
                           # --region eu-west-2  # set AWS_DEFAULT_REGION or pass --region via $@
                           #--end-time "$(date '+%s')000" \
jq -r '.events[].message' |
if [ -n "${DEBUG:-}" ]; then
    data="$(cat)"
    jq -r -s . <<< "$data" >&2
    cat <<< "$data"
else
    cat
fi |
jq -r -s '.[] |
          [
            .eventTime,
            .responseElements.jobId,
            ( .userIdentity.arn | sub("arn:aws:sts::\\d+:assumed-role/"; "") | sub("AWSReservedSSO_\\w+/"; "") ),
            .responseElements.jobName
          ] |
          @tsv'
