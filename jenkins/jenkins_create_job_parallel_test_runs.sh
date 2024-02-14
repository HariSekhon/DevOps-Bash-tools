#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-02-07 18:12:00 +0000 (Wed, 07 Feb 2024)
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

job_name='check-sleep-parallel'
job_xml="$srcdir/../setup/jenkins-job-sleep-parallel-parameterized.xml"

# shellcheck disable=SC2034,SC2154
usage_description="
Creates a freestyle parameterized test sleep job and launches N parallel runs of it to test scaling and parallelization of Jenkins on Kubernetes agents

Runs 10 jobs by default which run for 10 minutes each

The job configuration where this is specified is in:

    $job_xml

Uses the adjacent script jenkins_cli.sh

Jenkins authentication token and environment variables must be set - see jenkins_cli.sh for more details
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<number_of_job_runs_to_launch>]"

help_usage "$@"

max_args 1 "$@"

num_jobs="${1:-10}"

if ! is_int "$num_jobs"; then
    usage "argument must be an integer"
elif [ "$num_jobs" -gt 100 ]; then
    usage "argument is greater than 100, this seems like a costly mistake. Edit the protection in this script if you really want to do this"
fi

if ! [ -f "$job_xml" ]; then
    die "Job config file not found: $job_xml"
fi

timestamp "Checking if job '$job_name' already exists'"
if jenkins_cli.sh list-jobs | grep -q "^$job_name$"; then
    timestamp "Job '$job_name' already exists, skipping creation"
else
    timestamp "Job '$job_name' does not exist yet, creating..."
    "$srcdir/jenkins_cli.sh" create-job "$job_name" < "$job_xml"
fi

for ((i=1; i <= "$num_jobs"; i++)); do
    timestamp "Launching job $i"
    "$srcdir/jenkins_cli.sh" build "$job_name" -p "UNIQUE_VALUE=Run $i"
done
