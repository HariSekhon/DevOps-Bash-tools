#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: check-gcp-serviceaccount ../setup/jenkins-job-check-gcp-serviceaccount.xml
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

# shellcheck disable=SC2034,SC2154
usage_description="
Creates a Jenkins job from a given xml file and triggers it to run immediately

If the job already exists, skips creation
If the job already exists and the enviroment variable JENKINS_OVERWRITE_JOB is set to any value it updates the job definition

Uses the adjacent script jenkins_cli.sh

Jenkins authentication token and environment variables must be set - see jenkins_cli.sh for more details
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<job_name> <job_xml_file> [<jenkins_cli_options>]"

help_usage "$@"

min_args 2 "$@"

job_name="$1"
job_xml="$2"
shift || :
shift || :

if ! [ -f "$job_xml" ]; then
    die "Job config file not found: $job_xml"
fi

timestamp "Checking if job '$job_name' already exists'"
if jenkins_cli.sh list-jobs | grep -q "^$job_name$"; then
    if [ -n "${JENKINS_OVERWRITE_JOB:-}" ]; then
        timestamp "Job '$job_name' already exists, updating to ensure latest version"
        "$srcdir/jenkins_cli.sh" update-job "$job_name" < "$job_xml"
    else
        timestamp "Job '$job_name' already exists, skipping creation"
    fi
else
    timestamp "Job '$job_name' does not exist yet, creating..."
    "$srcdir/jenkins_cli.sh" create-job "$job_name" < "$job_xml"
fi

timestamp "Triggering job '$job_name'"
"$srcdir/jenkins_cli.sh" build "$job_name" "$@"
