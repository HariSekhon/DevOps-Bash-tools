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

job_name='check-gcp-serviceaccount'
job_xml="$srcdir/../setup/jenkins-job-check-gcp-serviceaccount.xml"

# shellcheck disable=SC2034,SC2154
usage_description="
Creates a freestyle test job which runs a GCP Metadata query to determine the GCP serviceaccount the agent pod is operating under   to check GKE Workload Identity integration

Triggers the job immediately to get the serviceaccount result

The job configuration where this is specified is in:

    $job_xml

Uses the adjacent script jenkins_cli.sh

Jenkins authentication token and environment variables must be set - see jenkins_cli.sh for more details
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

num_args 0 "$@"

export JENKINS_OVERWRITE_JOB=1

"$srcdir/jenkins_create_run_job.sh" "$job_name" "$job_xml"
