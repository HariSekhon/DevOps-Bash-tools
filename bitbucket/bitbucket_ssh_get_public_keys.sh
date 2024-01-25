#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-10-01 18:53:34 +0100 (Thu, 01 Oct 2020)
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
Gets the currently authenticated user's SSH key(s) for the BitBucket.org account via the BitBucket API

If you get an error it's possible you don't have the right token permissions.
You can generate a new token with the right permissions here:

    https://bitbucket.org/account/settings/app-passwords/

SSH Keys can be found in the Web UI here:

    https://bitbucket.org/account/settings/ssh-keys/


If \$BITBUCKET_USER is not set, then first queries the BitBucket API to determine this first

Uses the adjacent script bitbucket_api.sh, see there for authentication details
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

#min_args 1 "$@"

# this doc is wrong, doesn't accept either account id or uuid, but does accept username
#
#   https://developer.atlassian.com/bitbucket/api/2/reference/resource/users/%7Bselected_user%7D/ssh-keys
#
#account_id="$("$srcdir/bitbucket_api.sh" "/user" | jq -r '.account_id')"
#user_uuid="$("$srcdir/bitbucket_api.sh" "/user" | jq -r '.uuid')"
if [ -n "${BITBUCKET_USER:-}" ]; then
    user="$BITBUCKET_USER"
else
    echo "# Getting BitBucket user name via API call"
    user="$("$srcdir/bitbucket_api.sh" "/user" | jq -r '.username')"
fi

# XXX: not handling paging because if you have > 100 SSH keys I want to know what is going on first!

echo "# Fetching SSH Public Key(s) from BitBucket for account:  $user" >&2
echo "#" >&2
"$srcdir/bitbucket_api.sh" "/users/$user/ssh-keys" |
jq -r '.values[] | [ .key, .comment, .label ] | @tsv' |
tr '\t' ' ' |
sed "s|$| (bitbucket.org/$user)|"
