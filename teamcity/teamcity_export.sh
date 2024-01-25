#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-12-09 15:23:27 +0000 (Wed, 09 Dec 2020)
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
Exports TeamCity configs for projects, buildTypes and VCS roots to local directories of the same name as each project

This mimicks the directory structure of TeamCity's datadir and Versioned Settings VCS export integration

Project IDs can be specified as arguments, otherwise iterates over all discovered projects including the Root project
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<project_id1> <project_id2> ...]"

help_usage "$@"

#min_args 1 "$@"

basedir="$PWD"


# shellcheck disable=SC2103
if [ $# -gt 0 ]; then
    for project_id in "$@"; do
        echo "$project_id"
    done
else
    "$srcdir/teamcity_projects.sh" |
    awk '{print $1}'
fi |
# don't use grep -v it can pipefail
sed '/^[[:space:]]*$/d' |
sort -u |
while read -r project_id; do
    projectdir="$basedir/$project_id"
    mkdir -p -v "$projectdir"
    timestamp "Exporting TeamCity project '$project_id' to $projectdir"
    cd "$projectdir"
    # printed by the script
    #timestamp "Exporting project '$project_id' config"
    "$srcdir/teamcity_export_project_config.sh" "$project_id"
    mkdir -p -v buildTypes
    cd buildTypes
    #timestamp "Exporting project '$project_id' buildTypes"
    # restrict buildType exports to only this project
    TEAMCITY_BUILDTYPES_PROJECT="$project_id" "$srcdir/teamcity_export_buildtypes.sh"
    mkdir -p -v ../vcsRoots
    cd ../vcsRoots
    #timestamp "Exporting project '$project_id' VCS roots"
    TEAMCITY_VCS_ROOTS_PROJECT="$project_id" "$srcdir/teamcity_export_vcs_roots.sh"
    cd ..
    echo
done
