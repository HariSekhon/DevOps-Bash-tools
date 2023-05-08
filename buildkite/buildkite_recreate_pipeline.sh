#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-11 18:02:32 +0000 (Wed, 11 Mar 2020)
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

# shellcheck disable=SC2034
usage_description="
Recreates BuildKite pipeline to wipe out history (cancelling all build jobs skews the stats, this is a way of resetting them)

WARNING: the recreated pipeline will have the same name but a newly generated ID, invalidating the existing Status Badge URL
WARNING: the recreated pipeline will have a different webhook URL, so the GitHub webhook will need to be updated to keep triggering builds
Worse still, you cannot change the webhook URL back using the saved config as the API ignores the call, which is why the create step cannot set it properly

Creates a <pipeline_name>.json file in the local directory to prevent losing the pipeline configuration
if the create step fails for any reason after deleting the pipeline (does not pipe the get straight in to the create step)

Uses buildkite_get_pipeline.sh and buildkite_create_pipeline.sh adjacent scripts

Pipeline name is case sensitive and can be found via:

buildkite_api.sh /organizations/{organization}/pipelines | jq -r '.[].slug'

Organization name is also case sensitive and can be found via:

buildkite_api.sh /organizations | jq -r '.[].slug'

"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<pipeline> [<curl_options>]"

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
trap 'rm -- "$tmp"' $TRAP_SIGNALS

echo "saving pipeline '$pipeline' to local file '$config_file'"
"$srcdir/buildkite_get_pipeline.sh" "$pipeline" > "$config_file"
check_json_result "$config_file"

echo "deleting pipeline '$pipeline'"
"$srcdir/buildkite_api.sh" "/organizations/{organization}/pipelines/$pipeline" -X DELETE "$@" | tee "$tmp"
check_json_result "$tmp"

echo "recreating pipeline '$pipeline'"
"$srcdir/buildkite_create_pipeline.sh" "$config_file" "$@" > "$tmp"
check_json_result "$tmp"

echo "triggering build of recreated pipeline '$pipeline'"
"$srcdir/buildkite_trigger.sh" "$pipeline" > "$tmp"
check_json_result "$tmp"
