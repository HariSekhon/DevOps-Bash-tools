#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-04-01 18:33:42 +0100 (Wed, 01 Apr 2020)
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
usage_description="
# Lists BuildKite Agents via BuildKite API
#
# https://buildkite.com/docs/apis/rest-api/agents
"

# shellcheck disable=SC2034
usage_args="[<curl_options>]"

[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

BUILDKITE_ORGANIZATION="${BUILDKITE_ORGANIZATION:-${BUILDKITE_USER:-}}"

check_env_defined BUILDKITE_ORGANIZATION

help_usage "$@"

"$srcdir/buildkite_api.sh" "organizations/$BUILDKITE_ORGANIZATION/agents" "$@" |
jq -r '.[] | [.hostname, .ip_address, .created_at, .user_agent] | @tsv'
