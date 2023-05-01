#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-12-07 16:31:41 +0000 (Mon, 07 Dec 2020)
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
Enable or disable TeamCity VCS versioning for a project

Useful to stop auto-committing to GitHub when you're testing settings

Defaults to enable since you only want to disable VCS explicitly


See teamcity_api.sh for connection and authentication settings
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<projectID> [<enable|disable>]"

help_usage "$@"

min_args 1 "$@"

project="$1"

toggle="${2:-enable}"

if [[ "$toggle" =~ ^disabled?$ ]]; then
    value="false"
else
    value="true"
fi

feature_id="$("$srcdir/teamcity_api.sh" "/projects/$project" | jq -r '.projectFeatures.projectFeature[] | select(.type == "versionedSettings") | .id')"

# XXX: there is a slight race condition between getting and setting property back but the TeamCity API won't allow me to send only the enabled setting back - trying to send this resulted in wiping out the versionedSettings config
#"$srcdir/teamcity_api.sh" "/projects/$project/projectFeatures/id:$feature_id" -X PUT -d '{"type": "versionedSettings", "properties": { "property": [ { "name": "enabled", "value": "true" } ] } }'

# having to get whole property config, mangle and send back instead :'-(

settings="$("$srcdir/teamcity_api.sh" "/projects/$project/projectFeatures/id:$feature_id")"

index_of_property_enabled="$(jq '.properties.property | map(.name == "enabled") | index(true)' <<< "$settings")"

new_settings="$(jq ".properties.property[$index_of_property_enabled].value = \"$value\"" <<< "$settings")"

"$srcdir/teamcity_api.sh" "/projects/$project/projectFeatures/id:$feature_id" -X PUT -d "$new_settings"
