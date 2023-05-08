#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-16 09:52:29 +0100 (Sun, 16 Aug 2020)
#
#  https://gitlab.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://docs.gitlab.com/ee/api/users.html#delete-ssh-key-for-current-user
#
# Could also delete for a named user if you have admin permissions:
#
# https://docs.gitlab.com/ee/api/users.html#delete-ssh-key-for-given-user

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Deletes given SSH public key(s) from the currently authenticated GitLab account via the GitLab API

Accepts either a key ID or a case insensitive ERE regex to match against the key's title.
If multiple key titles match the given regex, deletes all of them.
If no keys match, does nothing.

SSH Keys can be found in the Web UI here:

    https://gitlab.com/profile/keys

If you get a 404 error it is likely that your \$GITLAB_TOKEN doesn't have the 'api' (full) permissions
You can regenerate a token with the right permissions here:

    https://gitlab.com/profile/personal_access_tokens

Uses the adjacent script gitlab_api.sh, see there for authentication details
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<key_id_or_title_regex>"

help_usage "$@"

min_args 1 "$@"

filter="$1"

timestamp "Getting SSH public keys"
"$srcdir/gitlab_api.sh" "/user/keys" |
jq -r '.[] | [.id, .title] | @tsv' |
while read -r key_id title; do
    if [ "$key_id" = "$filter" ] ||
       grep -Eqi "$filter" <<< "$title"; then
        "$srcdir/gitlab_api.sh" "/user/keys/$key_id" -X DELETE
        timestamp "Deleted SSH key with id '$key_id' and title '$title'"
    fi
done
