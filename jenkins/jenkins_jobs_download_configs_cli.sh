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

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Downloads all Jenkins job configs to files of the same name in the current directory via the Jenkins CLI

Tested on Jenkins 2.319

Uses the adjacent jenkins_cli.sh - see there for authentication details
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

timestamp "Downloading all Jenkins job configs to current directory: $PWD"

# something in jenkins_cli.sh is causing the loop to terminate early with no more lines
"$srcdir/jenkins_foreach_job_cli.sh" "
    '$srcdir/jenkins_cli.sh' get-job '{job}' </dev/null > '{job}.xml' &&
    echo >> '{job}.xml' &&
    echo 'Downloaded config to file: $PWD/{job}.xml'
    "
