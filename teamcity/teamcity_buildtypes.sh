#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-12-04 17:10:48 +0000 (Fri, 04 Dec 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://www.jetbrains.com/help/teamcity/rest-api-reference.html#Build+Requests

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Lists the Teamcity BuildTypes (pipelines) via the Teamcity API

Output format:

<BuildType_ID>    <Project>    <BuildType_Name>

Specify \$NO_HEADER to omit the header line

See adjacent teamcity_api.sh for authentication details
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<curl_options>]"

help_usage "$@"

{
if [ -z "${NO_HEADER:-}" ]; then
    printf 'BuildType_ID\tProject\tBuildType_Name\n'
fi
"$srcdir/teamcity_api.sh" /buildTypes |
jq -r '.buildType[] | [.id, .projectId, .name] | @tsv'
} |
# the $'' quoting evaluates the tab \t properly - has to be single not double quotes
column -t -s $'\t'
# POSIX, but above works just fine in bash
#column -t -s "$(printf '\t')"
