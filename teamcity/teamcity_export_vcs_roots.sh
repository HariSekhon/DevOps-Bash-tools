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

# https://www.jetbrains.com/help/teamcity/rest-api-reference.html#vcs_root+Configuration+And+Template+Settings

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Exports all TeamCity VCS roots to local JSON configuration files for backup/restore / migration purposes, or even just to backport changes to Git for revision control tracking

If arguments are specified then only downloads those named VCS roots, otherwise finds and downloads all VCS roots

If \$TEAMCITY_VCS_ROOTS_PROJECT is set then filters to only export the vcsRoots belonging to that project. If the project doesn't exit the API will return a 404 error


Uses the adjacent teamcity_api.sh and jq (installed by 'make')

See teamcity_api.sh for required connection settings and authentication

See teamcity_vcs_roots.sh for the list of vcs_roots and their IDs vs Names
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<vcs_root_id1> <vcs_root_id2> ...]"

help_usage "$@"

#min_args 1 "$@"

# prevent silent failures
trap 'echo ERROR' EXIT

if [ $# -gt 0 ]; then
    for vcs_root_id in "$@"; do
        echo "$vcs_root_id"
    done
else
    url_path="/vcs-roots"
    if [ -n "${TEAMCITY_VCS_ROOTS_PROJECT:-}" ]; then
        # XXX: this will 404 if the project doesn't exist
        url_path+="?locator=project:$TEAMCITY_VCS_ROOTS_PROJECT"
    fi
    "$srcdir/teamcity_api.sh" "$url_path" |
    jq -r '.["vcs-root"][] | [.id, .name] | @tsv'
fi |
sort -u |
# grep -v breaks pipe if no input eg. no vcs roots in _Root project
sed '/^[[:space:]]*$/d' |
while read -r vcs_root_id vcs_root_name; do
    # basing the filename off the ID instead of the Name is because it's more suitable for filenames
    # instead of 'github.com/harisekhon/blah (1)', 'MyProject_GithubComHariSekhonBlah1 ' is safer and easier to use in daily practice
    filename="$vcs_root_id.json"
    vcs_root_name="${vcs_root_name:-$vcs_root_id}"
    timestamp "Exporting vcs_root '$vcs_root_name' to '$filename'"
    "$srcdir/teamcity_api.sh" "/vcs-roots/$vcs_root_id" |
    # using jq just for formatting
    jq |
    # normalize the href's as they can be /app/rest or /httpAuth/app/rest depending on how you query it
    sed 's|/httpAuth/app/rest/|/app/rest/|' |
    cat > "$filename"
done

trap '' EXIT
