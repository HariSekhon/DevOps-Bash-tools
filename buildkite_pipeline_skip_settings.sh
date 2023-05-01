#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-12-17 15:07:11 +0000 (Thu, 17 Dec 2020)
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
Lists the cancel settings for a given BuildKite pipeline
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<pipeline>]"

help_usage "$@"

pipeline="${1:-}"

get_pipeline_settings(){
    local pipeline="$1"
    echo "Pipeline '$pipeline':"
    "$srcdir/buildkite_get_pipeline.sh" "$pipeline" |
    jq -r '[ .skip_queued_branch_builds,
             if .skip_queued_branch_builds_filter == "" then
                 "all"
             else
                 .skip_queued_branch_builds_filter
             end,
             .cancel_running_branch_builds,
             if .cancel_running_branch_builds_filter == "" then
                 "all"
             else
                 .cancel_running_branch_builds_filter
             end
           ] | @tsv' |
    while read -r skip_queued skip_branches cancel_running cancel_filter; do
        echo "Skip Intermediate Builds: $skip_queued"
        echo "Skip Intermediate Branches: $skip_branches"
        echo "Cancel Intermediate Builds: $cancel_running"
        echo "Cancel Intermediate Branches: $cancel_filter"
    done
    echo
}

if [ $# -gt 0 ]; then
    for pipeline in "$@"; do
        get_pipeline_settings "$pipeline"
    done
else
    for pipeline in $("$srcdir/buildkite_pipelines.sh"); do
        get_pipeline_settings "$pipeline"
    done
fi
