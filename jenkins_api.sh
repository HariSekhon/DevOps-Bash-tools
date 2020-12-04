#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-09-01 19:08:00 +0100 (Tue, 01 Sep 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

#  args: /user | jq .
#  args: /workspaces | jq .
#  args: /repositories/harisekhon | jq .
#  args: /repositories/harisekhon/devops-bash-tools/pipelines/ | jq .
#  args: /repositories/harisekhon/devops-bash-tools -X PUT -H 'Content-Type: application/json' -d '{"description": "some words"}'

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Queries the Jenkins Rest API

Can specify \$CURL_OPTS for options to pass to curl, or pass them as arguments to the script

Automatically handles authentication via environment variables \$JENKINS_USERNAME / \$JENKINS_USER and \$JENKINS_PASSWORD,
and obtains the Jenkins-Crumb cookie from a pre-request

Requires either \$JENKINS_URL or \$JENKINS_HOST + \$JENKINS_PORT which defaults to localhost and port 8080

If you require SSL, specify full \$JENKINS_URL

"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="/path [<curl_options>]"

JENKINS_URL="http://${JENKINS_URL:-${JENKINS_HOST:-localhost}:${JENKINS_PORT:-8080}}"

curl_api_opts "$@"

help_usage "$@"

min_args 1 "$@"

export USERNAME="${JENKINS_USERNAME:-${JENKINS_USER:-}}"
export PASSWORD="${JENKINS_PASSWORD:-${JENKINS_TOKEN:-}}"

url_path="${1:-}"
url_path="${url_path##/}"

shift || :

crumb="$("$srcdir/curl_auth.sh" -sS --fail "$JENKINS_URL/crumbIssuer/api/json" | jq -r '.crumb')"

"$srcdir/curl_auth.sh" "$JENKINS_URL/$url_path" -H "Jenkins-Crumb: $crumb" "${CURL_OPTS[@]}" "$@"
