#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-11-02 17:00:24 +0000 (Tue, 02 Nov 2021)
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
Lists AWS Batch jobs in a given queue older than N hours (default: 24)

Includes jobs stuck in pending and runnable states as these are usually stuck due to an environment/configuration issue if they've been pending for a long time

Useful to find jobs that have become too long running, eg. more than 24 hours, or jobs far exceeding their expected time, including jobs that can get stuck with memory allocation errors on shared VMs

Returns JSON list of jobs for further processing

Requires AWS CLI to be configured and authenticated
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<queue-name> [<hours>]"

help_usage "$@"

min_args 1 "$@"

queue="$1"
hours="${2:-24}"

# doesn't support floats
#millis="$((hours * 3600 * 1000))"
millis="$(bc -l <<< "$hours * 3600 * 1000" | sed 's/\..*$//')"

epoch_millis="$(date +%s)000"

before_epoch_millis="$((epoch_millis - millis))"

# --filters only works on newer versions of CLIv2 so jq processing is more reliable across environments:
#
#   https://github.com/aws/aws-cli/issues/6526
#
#aws batch list-jobs --job-queue "$queue" --filters "name=BEFORE_CREATED_AT,values=$before_epoch"

for state in SUBMITTED PENDING RUNNABLE STARTING RUNNING; do
    aws batch list-jobs --job-queue "$queue" --job-status "$state" |
    jq ".jobSummaryList[] | select(.createdAt <= $before_epoch_millis)"
done |
# slurp items back into an array
jq -s .
