#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-12-06 22:49:36 +0000 (Sun, 06 Dec 2020)
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
For a given TeamCity buildtype, finds the top GitHub VCS root and sync's the description from the GitHub repo to the TeamCity buildtype

TeamCity buildType ID is case sensitive

See Also:

    teamcity_buildtypes.sh - lists the build types showing ID, project and name
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<buildType_id>"

help_usage "$@"

min_args 1 "$@"

buildtype="$1"

buildtypes="$("$srcdir/teamcity_api.sh" "/buildTypes" | jq -r '.buildType[].id')"

if ! grep -Fxq "$buildtype" <<< "$buildtypes"; then
    die "TeamCity buildtype with ID '$buildtype' does not exist. Please run teamcity_buildtypes.sh to see the valid list of buildTypes and their IDs"
fi

vcs_root_ids="$("$srcdir/teamcity_api.sh" "/buildTypes/$buildtype" | jq -r '.["vcs-root-entries"]["vcs-root-entry"][]["vcs-root"]["id"]')"

vcs_root_id=""
repo=""
for id in $vcs_root_ids; do
    url="$("$srcdir/teamcity_api.sh" "/vcs-roots/$id" | jq -r '.properties.property[] | select(.name == "url") | .value')"
    shopt -s nocasematch
    if [[ "$url" =~ ^https://github.com/ ]]; then
        vcs_root_id="$id"
        repo="$(perl -pne 's|^https://github.com/||i' <<< "$url")"
    fi
    shopt -u nocasematch
done

if [ -z "$vcs_root_id" ]; then
    die "No GitHub.com VCS root url found in any of the attached VCS roots for buildType '$buildtype'"
fi

timestamp "Sync'ing TeamCity buildtype '$buildtype' description from GitHub repo '$repo'"
github_description="$("$srcdir/../github/github_repo_description.sh" "$repo" | cut -d $'\t' -f2-)"
"$srcdir/teamcity_api.sh" "/buildTypes/$buildtype/description" -X PUT -d "$github_description" -H "Content-Type: text/plain" -H "Accept: text/plain" >/dev/null
timestamp "Description set to '$github_description'"
