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

# https://docs.gitlab.com/ee/api/users.html#add-ssh-key-for-user

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Adds the given SSH public key(s) to the currently authenticated GitLab account via the GitLab API

If no SSH public key is given, defaults to using ~/.ssh/id_rsa.pub

If a dash is given, reads the SSH public key(s) from standard input, ignoring comment lines so you can chain with tools like the adjacent scripts:

    github_ssh_get_user_public_keys.sh
    gitlab_ssh_get_user_public_keys.sh
    github_ssh_get_public_keys.sh
    gitlab_ssh_get_public_keys.sh
    bitbucket_ssh_get_public_keys.sh

Will return a 400 error if the SSH public key is invalid or has already been added.
The script detects already existing keys and skips them to avoid this error

SSH Keys can be found in the Web UI here:

    https://gitlab.com/profile/keys

If you get a 404 error it is likely that your \$GITLAB_TOKEN doesn't have the 'api' (full) permissions
You can regenerate a token with the right permissions here:

    https://gitlab.com/profile/personal_access_tokens

Uses the adjacent script gitlab_api.sh, see there for authentication details
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<ssh_public_key_file> [<ssh_public_key_file2>]"

help_usage "$@"

#min_args 1 "$@"

echo "# Getting existing SSH public keys to skip any keys that already exist (to avoid 400 errors)" >&2
ssh_public_keys="$("$srcdir/gitlab_ssh_get_public_keys.sh")"

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
    comment="$(awk '{$1=""; $2=""; print}' <<< "$public_key" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    if grep -Fq "$key" <<< "$ssh_public_keys"; then
        timestamp "SSH public key already exists, skipping: '$public_key'"
        return
    fi
    timestamp "adding SSH public key to currently authenticated GitLab account: '$public_key'"
    # don't assume the key is from the local machine, it's likely this will be used by admins or chained with other tools that download from GitHub / BitBucket and upload to GitLab for synchronization, in which case the local machine is not related to the key
    #"$srcdir/gitlab_api.sh" "/user/keys" -X POST -H "Content-Type: application/json" -d '{"key": "'"$public_key"'", "title": "'"$USER@${HOSTNAME:-$(hostname)}"'"}' > /dev/null  # JSON of the newly added key
    "$srcdir/gitlab_api.sh" "/user/keys" -X POST -H "Content-Type: application/json" -d '{"title": "'"$comment"'", "key": "'"$public_key"'"}' |
    jq -r '"SSH public key \"" + .title + "\" was added to account as key id " + (.id|tostring)' |
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
