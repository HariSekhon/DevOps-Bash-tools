#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-24 13:10:46 +0100 (Mon, 24 Aug 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

#  args: /checks | jq .

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC1090
. "$srcdir/lib/git.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Queries the Pingdom API (v3.1)

Can specify \$CURL_OPTS for options to pass to curl, or pass them as arguments to the script

Automatically handles authentication via environment variable \$PINGDOM_TOKEN


You must set up an access token here:

https://my.pingdom.com/app/api-tokens


API Reference:

https://docs.pingdom.com/api/


Examples:


# Get Pingdom checks and statuses:

${0##*/} /checks
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="/path [<curl_options>]"

url_base="https://api.pingdom.com/api/3.1"

CURL_OPTS="-sS --fail --connect-timeout 3 ${CURL_OPTS:-}"

help_usage "$@"

check_env_defined "PINGDOM_TOKEN"

min_args 1 "$@"

url_path="${1:-}"
shift

url_path="${url_path##/}"

export TOKEN="$PINGDOM_TOKEN"

# need CURL_OPTS splitting, safer than eval
# shellcheck disable=SC2086
"$srcdir/curl_auth.sh" $CURL_OPTS "$url_base/$url_path" "$@"
