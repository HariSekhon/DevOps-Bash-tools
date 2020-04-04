#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-11 18:02:32 +0000 (Wed, 11 Mar 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<pipeline> [<curl_options>]"

# shellcheck disable=SC2034
usage_description="
Recreates BuildKite pipeline to wipe out history (cancelling all build jobs skews the stats, this is a way of resetting them)

Creates a <pipeline_name>.json file in the local directory to prevent losing the pipeline configuration
if the create step fails for any reason after deleting the pipeline (does not pipe the get straight in to the create step)

Uses buildkite_get_pipeline.sh and buildkite_create_pipeline.sh adjacent scripts

Pipeline name is case sensitive and can be found via:

buildkite_api.sh organizations/\$BUILDKITE_ORGANIZATION/pipelines | jq -r '.[].slug'

Organization name is also case sensitive and can be found via:

buildkite_api.sh organizations | jq -r '.[].slug'

"

[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

help_usage "$@"

pipeline="${1:-${BUILDKITE_PIPELINE:-${PIPELINE:-}}}"

if [ -z "$pipeline" ]; then
    usage "\$BUILDKITE_PIPELINE not defined and no argument given"
fi

config_file="$PWD/buildkite-pipeline.$pipeline.json"

check_json_result(){
    local filename="$1"
    # prints null
    #if jq -er '.message' < "$filename"; then
    if jq -er '.message' < "$filename" | grep -v '^null$' | grep '[A-Za-z]'; then
        exit 1
    fi
}

tmp="$(mktemp)"
# want splitting
# shellcheck disable=SC2086
trap 'rm "$tmp"' $TRAP_SIGNALS

echo "saving pipeline '$pipeline' to local file '$config_file'"
"$srcdir/buildkite_get_pipeline.sh" "$pipeline" > "$config_file"
check_json_result "$config_file"

echo "deleting pipeline '$pipeline'"
"$srcdir/buildkite_api.sh" "/organizations/$BUILDKITE_ORGANIZATION/pipelines/$pipeline" -X DELETE "$@" | tee "$tmp"
check_json_result "$tmp"

echo "recreating pipeline '$pipeline'"
"$srcdir/buildkite_create_pipeline.sh" "$config_file" "$@" | tee "$tmp"
check_json_result "$tmp"
