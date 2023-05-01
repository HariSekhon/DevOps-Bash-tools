#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-10-29 11:34:05 +0100 (Fri, 29 Oct 2021)
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
Queries all pipelines and prints the setting of executing forked pull requests to show which pipelines are vulnerable to arbitrary code execution

All pipelines should return 'false' otherwise they are vulnerable and should be updated using buildkite_pipeline_disable_forked_pull_requests.sh

Output:

    <pipeline_name_slug>    <true/false>


Uses adjacent scripts buildkite_foreach_pipeline.sh and buildkite_get_pipeline.sh
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

"$srcdir/buildkite_foreach_pipeline.sh" \
    "'$srcdir/buildkite_get_pipeline.sh' {pipeline} |
        jq -r '[.slug, .provider.settings.build_pull_request_forks] | @tsv'"
