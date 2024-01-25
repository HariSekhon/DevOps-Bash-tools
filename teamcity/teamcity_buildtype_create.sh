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

# https://www.jetbrains.com/help/teamcity/rest-api-reference.html#Build+Configuration+And+Template+Settings

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Creates a TeamCity BuildType (build pipeline) from a local JSON configuration file

Uses the adjacent teamcity_api.sh

See teamcity_api.sh for required connection settings and authentication
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<build.json>"

help_usage "$@"

min_args 1 "$@"

build_file="$1"

if ! [ -f "$build_file" ]; then
    die "ERROR: build file '$build_file' does not exit"
fi

if ! jq < "$build_file" > /dev/null; then
    die "ERROR: build file '$build_file' is not valid json"
fi

# XXX: technically this could have a different project ID and project name, in which case this won't work, they're assumed to usually be the same - if this is the case you must create the Project by hand, this should error out on the last line with an error if you've created your project name and id to be different
timestamp "determining project from build file"
project="$(jq -r '.project.name' < "$build_file")"

"$srcdir/teamcity_create_project.sh" "$project"
echo

timestamp "uploading build '$build_file' to TeamCity"

# XXX: can't export arrays in Bash :-( - must pass as a string and split inside teamcity_api.sh
# Update: unfortunately removing --fail causes curl to not error out properly, so other scripts that depend on this would not be notified of the failure, so only do this when debugging
#export CURL_OPTS="-sS" # this overrides teamcity_api.sh to not include --fail so we can get decent error messages here

# create build type using the given JSON configuration file

# API doesn't output newline, so we insert one ourselves to not mess up terminal output
set +e
"$srcdir/teamcity_api.sh" "/buildTypes" -X POST -d @"$build_file"
exitcode=$?
set -e
echo
exit $exitcode
