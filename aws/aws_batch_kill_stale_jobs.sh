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
Terminates AWS Batch jobs in a given queue older than N hours (default: 24)

Useful to find and kill jobs that have become too long running, eg. more than 24 hours, or jobs far exceeding their expected time, including jobs that can get stuck with memory allocation errors on shared VMs

May take a few seconds before the job(s) are actually terminated

Requires AWS CLI to be configured and authenticated
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<queue-name> [<hours>]"

help_usage "$@"

min_args 1 "$@"

queue="$1"
hours="${2:-24}"

script_basename="${0##*/}"

"$srcdir/aws_batch_stale_jobs.sh" "$queue" "$hours" |
jq -r '.[] | [.jobId,.jobName] | @tsv' |
while read -r job_id job_name; do
    timestamp "Terminating job id: '$job_id', name: '$job_name'"
    aws batch terminate-job --job-id "$job_id" --reason "Job terminated by script $script_basename after running for longer than $hours hours"
done
