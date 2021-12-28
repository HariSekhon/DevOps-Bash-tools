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
Searches CloudWatch Logs for AWS ECS task run requests in the last 24 hours to trace through to services incurring high EC2 charges such as large AWS Batch jobs

Defaults to finding logs in the last 24 hours but can optionally take an hours argument to search the last N hours, and can optionally take other AWS CLI options

Example:

    ${0##*/}

    ${0##*/} 48      # 48 hours ago to present

    ${0##*/} 24 12   # 24 hours ago to 12 hours ago

    ${0##*/} --start-time \"\$(date +%s --date='2021-12-21')000\" --end-time \"\$(date +%s --date='2021-12-23')000\"  # explicitly calculated dates, using standard AWS CLI options (now you see why I default to the simple hours ago optional args)


Output Format:

<timestamp>     <user>    <task_definition:version>

eg.

2021-12-23T02:05:34Z    aws-batch       MyJob:11



$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<hours_ago_start> <hours_ago_end> <aws_cli_options>]"

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

if ! [[ "$*" =~ --start-time ]]; then
    args+=( --start-time "$(date '+%s' --date="$hours_ago_start hours ago")000" )
fi
if ! [[ "$*" =~ --end-time ]]; then
    args+=( --end-time "$(date '+%s' --date="$hours_ago_end hours ago")000" )
fi

aws logs filter-log-events --log-group-name aws-controltower/CloudTrailLogs \
                           --filter-pattern '{ ($.eventSource = "ecs.amazonaws.com") && ($.eventName = "RunTask") }' \
                           ${args[@]:+"${args[@]}"} \
                           "$@" |
                           #--max-items 1 \
                           # --region eu-west-2  # set AWS_DEFAULT_REGION or pass --region via $@
jq -r '.events[].message' |
jq_debug_pipe_dump_slurp |
# 2021-12-23T02:05:34Z    aws-batch       arn:aws:ecs:eu-west-2:123456789012:task-definition/MyJob:11
jq -r -s '.[] |
          [
            .eventTime,
            ( .userIdentity.principalId | sub("^\\w+:"; "") ),
            ( .requestParameters.taskDefinition | sub("arn:aws:ecs:[\\w-]+:\\d+:task-definition/"; "") )
          ] |
          @tsv'
