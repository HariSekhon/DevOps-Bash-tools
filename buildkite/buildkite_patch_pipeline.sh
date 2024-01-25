#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-10-29 10:23:16 +0100 (Fri, 29 Oct 2021)
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
Patches a BuildKite pipeline from a partial JSON configuration provided either as an argument or on stdin

This JSON can be adapted from the download obtained by buildkite_get_pipeline.sh

Used by buildkite_pipeline_disable_forked_pull_requests.sh to protect your build environment from arbitrary code execution security vulnerabilities via Pull Requests
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<pipeline-name> <patchfile.json|json_literal> [<curl_options>]"

help_usage "$@"

min_args 1 "$@"

check_env_defined BUILDKITE_ORGANIZATION

pipeline="$1"
shift

if [ $# -ge 1 ]; then
    if [ -f "$1" ]; then
        pipeline_patch="$(cat "$1")"
        shift
    elif [[ "$1" =~ "{" ]]; then
        pipeline_patch="$1"
        shift
    else
        usage "patch.json not found and not interpreted as a json literal (missing brace)"
    fi
else
    echo "patch file argument not given, reading patch from stdin" >&2
    pipeline_patch="$(cat)"
fi

"$srcdir/buildkite_api.sh" "/organizations/$BUILDKITE_ORGANIZATION/pipelines/$pipeline" -X PATCH -d "$pipeline_patch" "$@"
