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

# https://developer.atlassian.com/bitbucket/api/2/reference/resource/users/%7Bselected_user%7D/ssh-keys#post

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Adds the given SSH public key(s) to the currently authenticated BitBucket.org account via the BitBucket API

If no SSH public key is given, defaults to using ~/.ssh/id_rsa.pub

If a dash is given, reads the SSH public key(s) from standard input, ignoring comment lines so you can chain with tools like the adjacent scripts:

    github_ssh_get_user_public_keys.sh
    gitlab_ssh_get_user_public_keys.sh
    github_ssh_get_public_keys.sh
    gitlab_ssh_get_public_keys.sh
    bitbucket_ssh_get_public_keys.sh

If you get an error it's possible you don't have the right token permissions.
You can generate a new token with the right permissions here:

    https://bitbucket.org/account/settings/app-passwords/

Will return a 400 error if the SSH public key is invalid or has already been added.
The script detects already existing keys and skips them to avoid this error

SSH Keys can be found in the Web UI here:

    https://bitbucket.org/account/settings/ssh-keys/

Uses the adjacent script bitbucket_api.sh, see there for authentication details
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<ssh_public_key_file> [<ssh_public_key_file2>]"

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

echo "# Getting existing SSH public keys to skip any keys that already exist (to avoid 400 errors)" >&2
ssh_public_keys="$("$srcdir/bitbucket_ssh_get_public_keys.sh")"

add_ssh_public_keys_from_file(){
    local public_key_file="$1"
    if [ "$public_key_file" = "-" ]; then
        public_key_file=/dev/stdin
    fi
    sed 's/#.*//; /^[[:space:]]*$/d' "$public_key_file" |
    while read -r public_key; do
        [[ "$public_key" =~ ^ssh- ]] || die "invalid SSH key in file '$public_key_file': $public_key"
        add_ssh_public_key "$public_key"
    done
}

add_ssh_public_key(){
    local public_key="$1"
    key="$(awk '{print $1" "$2}' <<< "$public_key")"
    if grep -Fq "$key" <<< "$ssh_public_keys"; then
        timestamp "SSH public key already exists, skipping: '$public_key'"
        return
    fi
    timestamp "adding SSH public key to currently authenticated BitBucket account: '$public_key'"
    # comment field will be populated from the key comment suffix, label is for the UI (which defaults to the comment otherwise but leaves the label field blank)
    # however, if I load someone else's public key or pipe from another download script, we certainly don't want it misleadingly marking the key as belonging to this machine, so more accurate to just rely on the SSH key comment
    #"$srcdir/bitbucket_api.sh" "/users/$user/ssh-keys" -X POST -H "Content-Type: application/json" -d '{"key": "'"$public_key"'", "label": "'"$USER@${HOSTNAME:-$(hostname)}"'"}' > /dev/null  # JSON of the newly added key
    "$srcdir/bitbucket_api.sh" "/users/$user/ssh-keys" -X POST -H "Content-Type: application/json" -d '{"key": "'"$public_key"'"}' |
    # > /dev/null  # JSON of the newly added key
    jq -r '[ "SSH public key added to account", .owner.display_name, "-", .comment ] | @tsv' |
    tr '\t' ' ' |
    timestamp "$(cat)"
    echo >&2
}

if [ $# -gt 0 ]; then
    for filename; do
        add_ssh_public_keys_from_file "$filename"
    done
else
    add_ssh_public_keys_from_file ~/.ssh/id_rsa.pub
fi
