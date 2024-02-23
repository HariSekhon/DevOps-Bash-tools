#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-02-23 01:13:35 +0000 (Fri, 23 Feb 2024)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://wiki.jenkins-ci.org/display/JENKINS/Remote+access+API

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Disables all Jenkins jobs/pipelines with names matching a given regex via the Jenkins API

Tested on Jenkins 2.319 and 2.246

Remember to quote the job name regex filter to stop it matching your local files eg. '.*' to not match '. .. .envrc'

Uses the adjacent jenkins_job_disable.sh jenkins_api.sh - see there for authentication details
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<job_name_regex_filter> [<curl_options>]"

help_usage "$@"

min_args 1 "$@"

if [[ "$*" =~ \.\ \.\. ]]; then
    die "You've specified an unquoted .* that has match . and .. directories - remember to quote your regex!"
fi

job_name_regex_filter="$1"
shift || :

timestamp "Getting job list"
"$srcdir/jenkins_jobs.sh" "$@" |
while read -r job_name; do
    if [[ "$job_name" =~ $job_name_regex_filter ]]; then
        "$srcdir/jenkins_job_disable.sh" "$job_name" "$@"
    fi
done
