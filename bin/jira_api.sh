#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-03-11 16:24:49 +0000 (Fri, 11 Mar 2022)
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
Queries the Jira API

Requires following environment variables to be defined:

    \$JIRA_USER  - eg. hari.sekhon@domain.com
    \$JIRA_TOKEN
    \$JIRA_DOMAIN - eg. mycompany (if your Jira URLs in your browser are https://mycompany.atlassian.net)

Can specify \$CURL_OPTS for options to pass to curl or provide them as arguments


Set up a personal access token here:

    https://id.atlassian.com/manage-profile/security/api-tokens


API Reference:

    https://developer.atlassian.com/cloud/jira/platform/rest/v3/intro/

    https://developer.atlassian.com/cloud/jira/platform/rest/v2/intro/


This defaults to API v3 but to use an older API such as v2 simply prefix the path with /2/


Examples:

# List Users:

    ${0##*/} /2/users/search | jq -r '.[].displayName' | sort -fu

# List Groups (admin privileges required otherwise gets 403 error):

    ${0##*/} /2/group | jq .

# List Projects:

    ${0##*/} /project/search | jq .

# List Issues:

    ${0##*/} /2/search?jql= | jq .

"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="/path [<curl_options>]"

check_env_defined JIRA_DOMAIN
check_env_defined JIRA_USER
check_env_defined JIRA_TOKEN

url_base="https://$JIRA_DOMAIN.atlassian.net/rest/api/3"

help_usage "$@"

min_args 1 "$@"

curl_api_opts "$@"

export USERNAME="$JIRA_USER"
export PASSWORD="$JIRA_TOKEN"

url_path="$1"
shift || :

if [[ "$url_path" =~ ^/?[[:digit:]]+(\.[[:digit:]]+)?/ ]]; then
    url_base="${url_base%%/3}"
fi
url_path="${url_path//$url_base}"
url_path="${url_path##/}"

"$srcdir/../bin/curl_auth.sh" "$url_base/$url_path" "${CURL_OPTS[@]}" "$@"
