#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-12-07 18:13:22 +0000 (Mon, 07 Dec 2020)
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
Creates TeamCity versioning for a given project

Requires a VCS root to already be configured and available - the ID provided as the second arg (defaults to 'TeamCity')

Recommend you create this VCS in the Root project and only enable on sub-projects since VCS sync with credentials omitted breaks its own VCS if you store it within the same project


Idempotent - detects if versioning is already configured for the given project and skips creation if so


If you want to force feature replacement of an already existing versionSetting configuration, set TEAMCITY_FORCE_FEATURE_REPLACE=1


See Also:

    teamcity_api.sh - for connection and authentication requirements, used by this script
    teamcity_projects.sh - lists projects and their IDs
    teamcity_vcs_roots.sh - lists VCS roots and their IDs
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<project_id> [<vcs_id>]"

help_usage "$@"

min_args 1 "$@"

project_id="$1"
vcs_id="${2:-TeamCity}"

feature_id="$("$srcdir/teamcity_api.sh" "/projects/$project_id" |
              jq -r '.projectFeatures.projectFeature[]? | select(.type == "versionedSettings") | .id')"
if [ -n "$feature_id" ]; then
    if [ -n "${TEAMCITY_FORCE_FEATURE_REPLACE:-}" ]; then
        timestamp "deleting all feature ids of type versionedSettings for project '$project_id'"
        for id in $feature_id; do
            "$srcdir/teamcity_api.sh" "/projects/$project_id/projectFeatures/id:$id" -X DELETE
        done
    else
        timestamp "TeamCity project '$project_id' is already configured for versionedSettings with id '$feature_id', skipping"
        exit 0
    fi
fi

# XXX: setting buildSettings to PREFER_VCS makes no different - TeamCity still demands write access to even load the config from VCS
timestamp "Creating version integration settings to VCS '$vcs_id' for project '$project_id'"
"$srcdir/teamcity_api.sh" "/projects/$project_id/projectFeatures" -X POST -d @<(cat <<EOF
      {
        "type": "versionedSettings",
        "properties": {
          "property": [
            {
              "name": "buildSettings",
              "value": "PREFER_CURRENT"
            },
            {
              "name": "credentialsStorageType",
              "value": "credentialsJSON"
            },
            {
              "name": "enabled",
              "value": "true"
            },
            {
              "name": "rootId",
              "value": "$vcs_id"
            },
            {
              "name": "showChanges",
              "value": "true"
            }
          ]
        }
      }
EOF
)
