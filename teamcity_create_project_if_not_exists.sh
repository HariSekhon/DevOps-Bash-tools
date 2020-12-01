#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-11-30 19:06:40 +0000 (Mon, 30 Nov 2020)
#
#  https://github.com/HariSekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://www.jetbrains.com/help/teamcity/rest-api-reference.html#Projects+and+Build+Configuration%2FTemplates+Lists

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Creates a TeamCity project if it doesn't already exist

Uses the adjacent teamcity_api.sh

See teamcity_api.sh for required connection settings and authentication

If you need to delete a project you can call

    teamcity_api.sh /projects/NAME -X DELETE
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<project_name>"

help_usage "$@"

min_args 1 "$@"

project="$1"

timestamp "checking if project '$project' already exists in TeamCity"
projects="$("$srcdir/teamcity_api.sh" "/projects" | jq -r '.project[].name')"
if grep -Fxq "$project" <<< "$projects"; then
    timestamp "project '$project' already exists in TeamCity"
else
    timestamp "creating project '$project' in TeamCity"
    # XXX: can't export arrays in Bash :-( - must pass as a string and split inside teamcity_api.sh
    export CURL_OPTS="-sS" # this overrides teamcity_api.sh to not include --fail so we can get decent error messages here
    # create new empty project
    set +e
    "$srcdir/teamcity_api.sh" "/projects/" \
        -X POST \
        -H "Content-Type: text/plain" \
        -d "$project"
        # can't use this for a simpler response, not valid
        #-H "Accept: text/plain" \
    # API doesn't output newline, so we insert one ourselves to not mess up terminal output
    exitcode=$?
    set -e
    echo
    exit $exitcode
fi
