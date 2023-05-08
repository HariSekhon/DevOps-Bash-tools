#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-04-04 14:38:58 +0100 (Sat, 04 Apr 2020)
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
Creates a BuildKite pipeline from a JSON configuration provided either as an argument or on stdin

This JSON file can be created from a configuration downloaded by buildkite_get_pipeline.sh

Used by buildkite_recreate_pipeline.sh to wipe out old history and reset stats
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="pipeline.json [<curl_options>]"

help_usage "$@"

if [ $# -ge 1 ] && [ -f "$1" ]; then
    pipeline_config="$(cat "$1")"
    shift
else
    echo "config file argument not given, reading config from stdin"
    pipeline_config="$(cat)"
fi

if [ -z "$BUILDKITE_ORGANIZATION" ]; then
    BUILDKITE_ORGANIZATION="$(jq -r '.url' <<< "$pipeline_config" | sed 's|https://api.buildkite.com/v.*/organizations/||; s|/pipelines/.*||')"
fi

check_env_defined BUILDKITE_TOKEN
check_env_defined BUILDKITE_ORGANIZATION

#if [ -z "$pipeline_config" ]; then
#    usage "pipeline config not given"
#fi

"$srcdir/buildkite_api.sh" "/organizations/$BUILDKITE_ORGANIZATION/pipelines" -X POST -d "$pipeline_config" "$@"
