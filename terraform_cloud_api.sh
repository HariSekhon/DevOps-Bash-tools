#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-11-12 14:37:10 +0000 (Fri, 12 Nov 2021)
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
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "${BASH_SOURCE[0]}")"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC1090
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


Examples:


# Get Account Details for the currently authenticated user:

    ${0##*/} /account/details | jq .

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

"$srcdir/curl_auth.sh" "$url_base/$url_path" "${CURL_OPTS[@]}" "$@"
