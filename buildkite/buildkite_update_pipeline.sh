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
Updates a BuildKite pipeline from a full JSON configuration provided either as an argument or on stdin

This JSON file can be created from a configuration downloaded by buildkite_get_pipeline.sh
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="pipeline.json [<curl_options>]"

help_usage "$@"

if [ $# -ge 1 ] && [ -f "$1" ]; then
    pipeline_config="$(cat "$1")"
    shift
else
    echo "config file argument not given, reading config from stdin" >&2
    pipeline_config="$(cat)"
fi

pipeline="$(jq -r '.slug' <<< "$pipeline_config" 2>/dev/null || :)"
pipeline="${pipeline:-${BUILDKITE_PIPELINE:-}}"

if [ -z "$BUILDKITE_ORGANIZATION" ]; then
    BUILDKITE_ORGANIZATION="$(jq -r '.url' <<< "$pipeline_config" | sed 's|https://api.buildkite.com/v.*/organizations/||; s|/pipelines/.*||')"
fi

check_env_defined BUILDKITE_ORGANIZATION

if [ -z "$pipeline" ]; then
    usage "\$BUILDKITE_PIPELINE not defined and couldn't be determined from JSON config"
fi

"$srcdir/buildkite_api.sh" "/organizations/$BUILDKITE_ORGANIZATION/pipelines/$pipeline" -X PATCH -d "$pipeline_config" "$@"
