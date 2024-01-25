#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-07-08 17:53:56 +0100 (Wed, 08 Jul 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://gerrit-review.googlesource.com/Documentation/rest-api-projects.html

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC2034
usage_description="
Queries Gerrit Code Review API for Project List, outputting in CSV format

Output Format:

<Project ID> , <State> , <Parent Project ID>, <Groups> , <Initial Commit Timestamp>, <Latest Master Commit Timestamp>

The following environment variables should be set before running:

\$GERRIT_HOST (default: localhost)
\$GERRIT_PORT (default: 8080)
\$GERRIT_SSL = 1 (default: blank which is off)
\$GERRIT_URL_PREFIX (default: blank, you might need to set /gerrit)

\$GERRIT_USER
\$GERRIT_PASSWORD
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<curl_options>]"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

host="${GERRIT_HOST:-localhost}"
port="${GERRIT_PORT:-8080}"

check_env_defined "GERRIT_USER"
check_env_defined "GERRIT_PASSWORD"

help_usage "$@"

protocol="http"
if [ -n "${GERRIT_SSL:-}" ]; then
    protocol="https"
fi

export USER="$GERRIT_USER"
export PASSWORD="$GERRIT_PASSWORD"

bugfix_gerrit_api_output(){
    sed "s/^)]}'//"
}

curl_options="-sSL $*"

url_prefix=""
if [ -n "${GERRIT_URL_PREFIX:-}" ]; then
    GERRIT_URL_PREFIX="${GERRIT_URL_PREFIX#/}"
    GERRIT_URL_PREFIX="${GERRIT_URL_PREFIX%/}"
    url_prefix="/$GERRIT_URL_PREFIX"
fi

# /a/ prefix for authenticated API access - https://gerrit-review.googlesource.com/Documentation/rest-api.html#authentication
base_url="$protocol://$host:$port${url_prefix}/a"

curl_auth(){
    local url_path="$1"
    shift || :
    # need opt splitting
    # shellcheck disable=SC2086
    "$srcdir/../bin/curl_auth.sh" "$base_url/$url_path" -H 'Content-type: application/json' "$@" $curl_options |
    bugfix_gerrit_api_output
}

curl_auth "projects/" |
jq -r 'to_entries | .[] | .value | [.id, .state] | @tsv' |
while read -r project_id state; do
    parent="$(curl_auth "projects/$project_id/parent" | tr -d '\n')"
    parent="${parent//\"}"
    groups="$(curl_auth "projects/$project_id/access" | jq -r '([(.groups | to_entries | .[].value.name)] | join(","))')"
    groups="${groups//\"}"
    # might not have a timestamp, in which case ignore failures
    # Also the reflog might get limited and not return the real full git lot to find the initial commit.
    # It doesn't look like this creation timestamp is available in the /projects/ API directly
    initial_commit_timestamp="$(curl_auth "projects/$project_id/branches/master/reflog" | jq -r 'last | .who.date' 2>/dev/null || :)"
    initial_commit_timestamp="${initial_commit_timestamp//\"}"
    latest_commit_timestamp="$(curl_auth "projects/$project_id/branches/master/reflog" | jq -r 'limit(1; .[] | .who.date)' 2>/dev/null || :)"
    latest_commit_timestamp="${latest_commit_timestamp//\"}"
    echo "\"$project_id\",\"$state\",\"$parent\",\"$groups\",\"$initial_commit_timestamp\", \"$latest_commit_timestamp\""
done
