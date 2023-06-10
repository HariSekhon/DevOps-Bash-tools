#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: /models
#
#  Author: Hari Sekhon
#  Date: 2023-06-10 21:45:48 +0100 (Sat, 10 Jun 2023)
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
Queries the OpenAI API

Automatically handles authentication via environment variable \$OPENAI_API_KEY
If a member of multiple organizations then you must also set \$OPENAI_ORGANIZATION_ID

Can specify \$CURL_OPTS for options to pass to curl or provide them as arguments


Set up your API key here:

    https://platform.openai.com/account/api-keys

If you are a member of multiple organizations, get the Organization ID here:

    https://platform.openai.com/account/org-settings


API Reference:

    https://platform.openai.com/docs/api-reference/introduction


Examples:


List Models:

    ${0##*/} /models

Retrieve Model:

    ${0##*/} /models/{model_id}

    ${0##*/} /models/gpt-3.5-turbo

List Files in our org:

    ${0##*/} /files

Get File metadata:

    ${0##*/} /files/{file_id}

Get File content:

    ${0##*/} /files/{file_id}/content

List fine-tuning jobs:

    ${0##*/} /fine-tunes

Retrieve fine-tune:

    ${0##*/} /fine-tunes/{fine_tune_id}
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="/path [<curl_options>]"

url_base="https://api.openai.com/v1"

help_usage "$@"

min_args 1 "$@"

check_env_defined OPENAI_API_KEY

curl_api_opts "$@"

url_path="$1"
shift || :

url_path="${url_path//https:\\/\\/api.openai.com\/v1}"
url_path="${url_path##/}"

export TOKEN="$OPENAI_API_KEY"

if [ -n "${OPENAI_ORGANIZATION_ID:-}" ]; then
    CURL_OPTS+=(-H "OpenAI-Organization: $OPENAI_ORGANIZATION_ID")
fi

"$srcdir/../bin/curl_auth.sh" "$url_base/$url_path" ${CURL_OPTS:+"${CURL_OPTS[@]}"} "$@" |
jq_debug_pipe_dump
