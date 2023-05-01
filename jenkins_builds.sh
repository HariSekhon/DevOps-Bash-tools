#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-06-30 10:42:58 +0100 (Thu, 30 Jun 2022)
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
Lists the latest builds and their statuses for all the Jenkins jobs/pipelines

Output Format:

<timestamp>    <duration>    <build_number>    <result>    <name>


Tested on Jenkins 2.319

Uses jenkins_api.sh - see there for authentication and connection details
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

jenkins_api.sh '/api/json?tree=jobs\[name,lastBuild\[number,timestamp,duration,building,result\]\]&pretty=true' |
jq -r '.jobs[] |
        [
            .lastBuild.timestamp,
            .lastBuild.number,
            .lastBuild.building,
            .lastBuild.result,
            .lastBuild.duration,
            .name
        ] | @tsv' |
sort -r |
while read -r timestamp_millis number building result duration_millis name; do
    if ! [[ "$timestamp_millis" =~ ^[[:digit:]]+$ ]]; then
        # not builds have been run for this pipeline yet, populate defaults to avoid errors
        name="$timestamp_millis $number $building $result $duration_millis $name"
        timestamp_millis=0
        number="0"
        result="N/A"
        duration_millis=0
    fi
    timestamp=$((timestamp_millis / 1000))
    datestamp="$(date -d "@$timestamp" '+%FT%T')"
    if [ "$building" = true ]; then
        result="BUILDING"  # result is blank otherwise
        name="$duration_millis $name"  # this eats the first word of name if the prior column is blank
        duration="$(($(date '+%s') - timestamp))"
    else
        duration="$((duration_millis / 1000))"
    fi
    duration="$(seconds_to_hours "$duration")"
    printf '%s\t%12s\t%8d\t%-10s\t%s\n' "$datestamp" "$duration" "$number" "$result" "$name"
done
