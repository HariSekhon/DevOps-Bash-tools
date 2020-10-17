#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-10-13 20:18:20 +0100 (Tue, 13 Oct 2020)
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
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034
usage_description="
Returns a Codeship access token from the Codeship API using basic authentication

Requires \$CODESHIP_USERNAME / \$CODESHIP_USER and \$CODESHIP_PASSWORD to be defined in the environment

Codeship user is usually your email address and if using GitHub OAuth sign-in, you'll need to set a normal password via this link:

    https://app.codeship.com/password_reset/new
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<curl_options>]"

help_usage "$@"

CURL_OPTS="-sS --fail --connect-timeout 3 ${CURL_OPTS:-}"

check_env_defined "CODESHIP_PASSWORD"

user="${CODESHIP_USERNAME:-${CODESHIP_USER:-}}"
if [ -z "$user" ]; then
    die "\$CODESHIP_USERNAME / \$CODESHIP_USER not defined"
fi

export USER="$user"
export PASSWORD="$CODESHIP_PASSWORD"

# want arg splitting
# shellcheck disable=SC2086
output="$("$srcdir/curl_auth.sh" https://api.codeship.com/v2/auth -X POST -H "Content-Type: application/json" -H "Accept: application/json" "$@" $CURL_OPTS)"

die_if_error_field "$output"

if [ -n "${DEBUG:-}" ]; then
    # pretty print for human convenience / developer review
    jq . <<< "$output" >&2
fi

jq -r '.access_token' <<< "$output"
