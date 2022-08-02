#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-08-02 19:20:38 +0100 (Tue, 02 Aug 2022)
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

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Queries the Octopus Deploy API

\$OCTOPUS_URL should be set to your server

API Reference:

    https://octopus.com/docs/octopus-rest-api

"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="/path [<curl_options>]"

check_env_defined "OCTOPUS_URL"
check_env_defined "OCTOPUS_TOKEN"

help_usage "$@"

min_args 1 "$@"

curl_api_opts "$@"

url_path="$1"
shift || :

export TOKEN="$OCTOPUS_TOKEN"
export CURL_AUTH_HEADER="X-Octopus-ApiKey"

url_base="$OCTOPUS_URL"

"$srcdir/curl_auth.sh" "$url_base/$url_path" ${CURL_OPTS:+"${CURL_OPTS[@]}"} "$@" |
jq_debug_pipe_dump
