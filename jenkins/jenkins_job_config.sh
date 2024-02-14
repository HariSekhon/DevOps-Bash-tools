#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-06-28 18:34:34 +0100 (Tue, 28 Jun 2022)
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
Gets or Sets the Jenkins job/pipeline config via the Jenkins API

Tested on Jenkins 2.319 and 2.426

Uses the adjacent jenkins_api.sh - see there for authentication details


Example:

    # Get the current job's configuration:

        ${0##*/} myJob

    # Set a new job configuration:

        ${0##*/} myJob myConfig.xml

    # Pretty-print through xmllint:

        ${0##*/} myJob | xmllint --format
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<job_name> [<config.xml>]"

help_usage "$@"

min_args 1 "$@"

job="$1"
config_file="${2:-}"

if [ -n "$config_file" ]; then
    if ! [ -f "$config_file" ]; then
        die "Config file not found: $config_file"
    fi
    "$srcdir/jenkins_api.sh" "/job/$job/config.xml" -X POST -d @"$config_file"
    timestamp "Set Jenkins job '$job' config"
else
    "$srcdir/jenkins_api.sh" "/job/$job/config.xml"
    # because there isn't a newline at the end
    echo
fi
