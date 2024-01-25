#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-16 09:52:29 +0100 (Sun, 16 Aug 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://docs.github.com/en/free-pro-team@latest/rest/reference/users#delete-a-public-ssh-key-for-the-authenticated-user

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Deletes given SSH public key(s) from the currently authenticated GitHub account via the GitHub API

Accepts either a key ID or a case insensitive ERE regex to match against the key's title.
If multiple key titles match the given regex, deletes all of them.
If no keys match, does nothing.

SSH Keys can be found in the Web UI here:

    https://github.com/settings/keys

If you get a 404 error it's likely that your \$GITHUB_TOKEN doesn't have the admin:public_key permission
You can edit the permissions your token has here:

    https://github.com/settings/tokens

Uses the adjacent script github_api.sh, see there for authentication details
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<key_id_or_title_regex>"

help_usage "$@"

min_args 1 "$@"

filter="$1"

timestamp "Getting SSH public keys"
"$srcdir/github_api.sh" "/user/keys" |
jq -r '.[] | [.id, .title] | @tsv' |
while read -r key_id title; do
    if [ "$key_id" = "$filter" ] ||
       grep -Eqi "$filter" <<< "$title"; then
        "$srcdir/github_api.sh" "/user/keys/$key_id" -X DELETE
        timestamp "Deleted SSH key with id '$key_id' and title '$title'"
    fi
done
