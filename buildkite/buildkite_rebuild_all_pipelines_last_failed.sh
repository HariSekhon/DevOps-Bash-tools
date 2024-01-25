#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-06-08 12:08:41 +0100 (Tue, 08 Jun 2021)
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
Rebuilds the last failed build on each pipeline in the current organization

See adjacent scripts for more details:

    buildkite_foreach_pipeline.sh
    buildkite_rebuild_failed_builds.sh
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

"$srcdir/buildkite_foreach_pipeline.sh" "$srcdir/buildkite_rebuild_failed_builds.sh" '{pipeline}' 1

# All Failed builds in history
#
#"$srcdir/buildkite_api.sh" "builds?state=failed" "$@" |
#jq -r '.[] | [.pipeline.slug, .number, .url] | @tsv' |
#while read -r name number url; do
#    url="${url#https://api.buildkite.com/v2/}"
#    echo -n "Rebuilding $name build number $number:  "
#    "$srcdir/buildkite_api.sh" "$url/rebuild" -X PUT |
#    jq -r '.state'
#done
