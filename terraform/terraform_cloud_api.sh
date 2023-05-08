#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-11-12 14:37:10 +0000 (Fri, 12 Nov 2021)
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

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/git.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Queries the Terraform Cloud API

Authentication requites the environment variable \$TERRAFORM_TOKEN to be set

Can specify \$CURL_OPTS for options to pass to curl or provide them as arguments


Set up a personal access token here:

    https://app.terraform.io/app/settings/tokens


API Reference:

    https://www.terraform.io/docs/cloud/api/index.html


For convenience, the following tokens in the format ':token' or '{token}' are automatically replaced if the environment variables are available, for easy copy-pasting from API documentation:

:org, :organization, :organization_name         \$TERRAFORM_ORGANIZATION
:workspace, :workspace_id                       \$TERRAFORM_WORKSPACE
:user, :userid, :user_id                        \$TERRAFORM_USER_ID, otherwise must make extra call to API to determine


Examples:


# Get Account Details for the currently authenticated user:

    ${0##*/} /account/details | jq .


# Get Account Details for a given user (doesn't contain email like /account/details self-describing endpoint):

    ${0##*/} /users/{userid} | jq .


# Get your user ID (export as \$TERRAFORM_USER_ID for other queries):

    ${0##*/} /account/details | jq .data.id

    export TERRAFORM_USER_ID=\"\$(${0##*/} /account/details | jq .data.id)\"


# List organizations:

    ${0##*/} /organizations | jq .


# List workspaces:

    ${0##*/} /organizations/:organization_name/workspaces | jq .


# List an organization's variable sets:

    ${0##*/} /organizations/:organization_name/varsets | jq .


# List workspace variables (see terraform_cloud_workspace_set_vars.sh for an easy way to add/update them):

    ${0##*/} /workspaces/:workspace_id/vars | jq .

# See terraform_cloud_*_vars.sh for easier listing/adding/updating/deleting variables in workspaces and variable sets


# Lock/Unlock a workspace:

    ${0##*/} /workspaces/:workspace_id/actions/lock -X POST | jq .
    ${0##*/} /workspaces/:workspace_id/actions/unlock -X POST | jq .


# List workspace resources:

    ${0##*/} /workspaces/:workspace_id/resources | jq .


# IP Ranges used by Terraform Cloud (see terraform_cloud_ip_ranges.sh for a processed version, one per line):

    ${0##*/} /meta/ip-ranges | jq .


# Registry Modules for an org:

    ${0##*/} /organizations/{org}/registry-modules | jq .


# Get Agent Pools:

    ${0##*/} /organizations/{organization}/agent-pools | jq .


# Get Audit Trails:

    ${0##*/} /organization/audit-trail | jq .


# Get Feature Sets:

    ${0##*/} /feature-sets | jq .


# Get your user authentication tokens (eg. to check for old tokens programmatically):

    ${0##*} /users/{userid}/authentication-tokens | jq .


# Create a new user token:

    ${0##*} /users/{userid}/authentication-tokens -X POST | jq .

# Delete a user token:

    ${0##*} /authentication-tokens/{id} -X DELETE | jq .
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="/path [<curl_options>]"

url_base="https://app.terraform.io/api/v2"

help_usage "$@"

min_args 1 "$@"

curl_api_opts "$@"

check_env_defined TERRAFORM_TOKEN

export TOKEN="$TERRAFORM_TOKEN"

url_path="${1:-}"
shift || :

# stripping url_base for convenience in case copying and pasting from docs
url_path="${url_path//https:\/\/app.terraform.io\/api\/v2}"
url_path="${url_path##/}"

if [[ "$url_path" =~ [\{:]org(anization)?(_?name)?\}? ]]; then
    if [ -n "${TERRAFORM_ORGANIZATION:-}" ]; then
        url_path="${url_path//:organization_name/$TERRAFORM_ORGANIZATION}"
        url_path="${url_path//:organization/$TERRAFORM_ORGANIZATION}"
        url_path="${url_path//:org/$TERRAFORM_ORGANIZATION}"
        url_path="${url_path//\{organization_name\}/$TERRAFORM_ORGANIZATION}"
        url_path="${url_path//\{organization\}/$TERRAFORM_ORGANIZATION}"
        url_path="${url_path//\{org\}/$TERRAFORM_ORGANIZATION}"
    else
        die "organization placeholder found but \$TERRAFORM_ORGANIZATION is not set"
    fi
fi

if [[ "$url_path" =~ [\{:]workspace(_?id)?\}? ]]; then
    if [ -n "${TERRAFORM_WORKSPACE:-}" ]; then
        url_path="${url_path//:workspace_id/$TERRAFORM_WORKSPACE}"
        url_path="${url_path//:workspace/$TERRAFORM_WORKSPACE}"
        url_path="${url_path//\{workspace_id\}/$TERRAFORM_WORKSPACE}"
        url_path="${url_path//\{workspace\}/$TERRAFORM_WORKSPACE}"
    else
        die "workspace placeholder found but \$TERRAFORM_WORKSPACE is not set"
    fi
fi

if [[ "$url_path" =~ [\{:]?user(_?id)?\}? ]]; then
    if [ -n "${TERRAFORM_USER_ID:-}" ]; then
        url_path="${url_path//:user_id/$TERRAFORM_USER_ID}"
        url_path="${url_path//:userid/$TERRAFORM_USER_ID}"
        url_path="${url_path//:user/$TERRAFORM_USER_ID}"
        url_path="${url_path//\{user\}/$TERRAFORM_USER_ID}"
        url_path="${url_path//\{userid\}/$TERRAFORM_USER_ID}"
        url_path="${url_path//\{user_id\}/$TERRAFORM_USER_ID}"
    else
        user_id="$("$srcdir/../bin/curl_auth.sh" "${CURL_OPTS[@]}" "$url_base/account/details" | jq -r .data.id)"
        url_path="${url_path//:user_id/$user_id}"
        url_path="${url_path//:userid/$user_id}"
        url_path="${url_path//:user/$user_id}"
        url_path="${url_path//\{user\}/$user_id}"
        url_path="${url_path//\{userid\}/$user_id}"
        url_path="${url_path//\{user_id\}/$user_id}"
    fi
fi

"$srcdir/../bin/curl_auth.sh" "$url_base/$url_path" "${CURL_OPTS[@]}" "$@"
