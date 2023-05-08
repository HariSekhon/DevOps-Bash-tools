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
Lists BuildKite pipelines in slug format (re-usable in API), one per line to make it easy to iterate on them

eg. trigger a build of each pipeline:

./buildkite_pipelines.sh | while read pipeline; do ./buildkite_trigger.sh \"\$pipeline\"; done
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<curl_options>]"

help_usage "$@"

"$srcdir/buildkite_api.sh" "/organizations/{organization}/pipelines" | jq -r '.[].slug'
