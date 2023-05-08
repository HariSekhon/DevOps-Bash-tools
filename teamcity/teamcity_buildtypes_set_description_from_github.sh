#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-12-07 17:09:00 +0000 (Mon, 07 Dec 2020)
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
For each TeamCity buildType in the given project, or all projects if none given, attempt to sync the first VCS GitHub repo description to the buildType description

See Also:

    teamcity_api.sh - see here for connection and authentication details
    teamcity_projects.sh - lists projects and their IDs
    teamcity_buildtype_set_description_from_github.sh - sets a single buildtype's description to match its first GitHub VCS
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<project_id>]"

help_usage "$@"

#min_args 1 "$@"

project="${1:-}"

if [ -n "$project" ]; then
    echo "$project"
else
    "$srcdir/teamcity_api.sh" /projects |
    jq -r '.project[].id'
fi |
while read -r project_id; do
    timestamp "getting list of buildtypes in project '$project_id'"
    echo
    "$srcdir/teamcity_api.sh" "/projects/$project_id" |
    jq -r '.buildTypes.buildType[].id' |
    while read -r buildtype_id; do
        "$srcdir/teamcity_buildtype_set_description_from_github.sh" "$buildtype_id"
        echo
    done
    echo
done
