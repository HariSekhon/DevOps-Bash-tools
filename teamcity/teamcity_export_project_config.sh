#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-11-30 19:06:40 +0000 (Mon, 30 Nov 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://www.jetbrains.com/help/teamcity/rest-api-reference.html#project+Configuration+And+Template+Settings

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Exports all TeamCity Projects to local JSON configuration files for backup/restore / migration purposes, or even just to backport changes to Git for revision control tracking

If arguments are specified then only downloads those named Projects, otherwise finds and downloads all Projects settings.

If a single project is given, the export filename is called project-settings.json in line with standard TeamCity exports, but if multiple projects are given or the project list is queried from TeamCity then the export file is called <project>.json to differentiate them.


Uses the adjacent teamcity_api.sh and jq (installed by 'make')

See teamcity_api.sh for required connection settings and authentication

See teamcity_projects.sh for the list of projects and their IDs vs Names
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<project_id1> <project_id2> ...]"

help_usage "$@"

#min_args 1 "$@"

# use this to figure out if we should set filename to <project>.json or leave as the single standard project-config.json - this is important for bulk teamcity_export.sh per project to mimick the official TeamCity exports and Versioned Settings sync directory structure
export projects=("$@")
filename="project-config.json"

if [ $# -gt 0 ]; then
    for project_id in "$@"; do
        echo "$project_id"
    done
else
    "$srcdir/teamcity_api.sh" /projects |
    jq -r '.project[] | [.id, .name] | @tsv'
fi |
# grep -v breaks pipe if no input, prefer sed
sed '/^[[:space:]]*$/d' |
while read -r project_id project_name; do
    # basing the filename off the ID instead of the Name is because it's more suitable for filenames
    # instead of '<Root>.json', '_Root.json' is safer and easier to use in daily practice
    if [ ${#projects[@]} -gt 1 ]; then
        filename="$project_id.json"
    fi
    project_name="${project_name:-$project_id}"
    timestamp "Exporting project '$project_name' config to '$filename'"
    #project_name="$("$srcdir/../bin/urlencode.sh" <<< "$project_name")"
    #"$srcdir/teamcity_api.sh" "/projects/$project_name" |
    "$srcdir/teamcity_api.sh" "/projects/$project_id" |
    # using jq just for formatting
    jq |
    # normalize the href's as they can be /app/rest or /httpAuth/app/rest depending on how you query it
    sed 's|/httpAuth/app/rest/|/app/rest/|' |
    cat > "$filename"
done
