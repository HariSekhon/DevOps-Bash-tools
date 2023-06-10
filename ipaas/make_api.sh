#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2023-06-10 22:44:21 +0100 (Sat, 10 Jun 2023)
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
Queries the Make.com API

Automatically handles authentication via environment variable \$MAKE_API_KEY
Must also set the \$MAKE_ZONE eg. 'eu1'

Replaces {organizationId} in the URL with \$MAKE_ORGANIZATION_ID if set, otherwise queries the API and uses the first organization returned by the API

Can specify \$CURL_OPTS for options to pass to curl or provide them as arguments


Set up your API token here:

    https://eu1.make.com/user/api


API Reference:

    https://www.make.com/en/api-documentation


Examples:

Some of these may not work on the free plan, see this issue:

    https://community.make.com/t/erro-403-permission-denied-forbidden-to-use-token-authorization-for-this-organization/9946


Ping the API:

    ${0##*/} /ping

Get currently authenticated user:

    ${0##*/} /users/me | jq .

List users / teams / organizations / license:

    # 403 - VPN access only
    #${0##*/} /admin/users
    #${0##*/} /admin/teams
    #${0##*/} /admin/organizations
    #${0##*/} /admin/system-settings/default-license

List Connections:

    ${0##*/} /connections?teamId=...

List Data Stores:

    ${0##*/} /data-stores?teamId=...

List Hooks:

    ${0##*/} /hooks?teamId=...

List Notifications:

    ${0##*/} /notifications | jq .

List User's Organizations (shows API limit here):

    ${0##*/} /organizations | jq .

Get Organization Details:

    ${0##*/} /organizations/{organizationId}

List Scenarios:

    ${0##*/} /scenarios?teamId=...

List Teams:

    ${0##*/} /teams?organizationId={organizationId}

List Templates:

    ${0##*/} /templates

List Users:

    ${0##*/} /users?organizationId={organizationId} | jq .
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="/path [<curl_options>]"

help_usage "$@"

min_args 1 "$@"

check_env_defined MAKE_API_KEY
check_env_defined MAKE_ZONE

url_base="https://$MAKE_ZONE.make.com/api/v2"

curl_api_opts "$@"

url_path="$1"
shift || :

url_path="${url_path//https:\\/\\/*.make.com\/api/v2}"
url_path="${url_path##/}"

export CURL_AUTH_HEADER="Authorization: Token"
export TOKEN="$MAKE_API_KEY"

if [[ "$url_path" =~ {organizationId} ]]; then
    if [ -z "${MAKE_ORGANIZATION_ID:-}" ]; then
        MAKE_ORGANIZATION_ID="$("$0" /organizations | jq -Mr '.organizations[0].id')"
    fi
    url_path="${url_path/\{organizationId\}/$MAKE_ORGANIZATION_ID}"
fi

"$srcdir/../bin/curl_auth.sh" "$url_base/$url_path" ${CURL_OPTS:+"${CURL_OPTS[@]}"} "$@" |
jq_debug_pipe_dump
