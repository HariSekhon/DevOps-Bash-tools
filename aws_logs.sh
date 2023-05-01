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
Search CloudWatch Logs, inserting a more human friendly hours ago optional args to generate the --start-time and --end-time epochs in milliseconds

Defaults to finding logs in the last 24 hours but can optionally take an hours argument to search the last N hours

You must supply the --log-group-name and --filter-pattern arguments in addition to potentially supplying the hours ago args at the start

Examples:

    ${0##*/} --log-group-name aws-controltower/CloudTrailLogs --filter-pattern '{ ($.eventSource = \"batch.amazonaws.com\") && ($.eventName = \"SubmitJob\") }'

    ${0##*/} 48 ...    # start 48 hours ago to present

    ${0##*/} 24 3 ...  # start 24 hours ago up to to 3 hours ago

    ${0##*/} --start-time \"\$(date +%s --date='2021-12-21')000\" --end-time \"\$(date +%s --date='2021-12-23')000\"  ... # explicitly calculated dates, using standard AWS CLI options (now you see why I default to the simple hours ago optional args)


Output Format in AWS JSON


$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<hours_ago_start> <hours_ago_end> <aws_cli_options>]"

help_usage "$@"

min_args 4 "$@"

export AWS_DEFAULT_OUTPUT=json

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

aws logs filter-log-events ${args[@]:+"${args[@]}"} \
                           "$@"
                           #--max-items 1 \
                           # --region eu-west-2  # set AWS_DEFAULT_REGION or pass --region via $@
                           #--end-time "$(date '+%s')000" \
