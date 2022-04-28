#!/usr/bin/env bash
#
#  Author: Hari Sekhon
#  Date: 2019-09-18
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying LICENSE file
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://docs.github.com/en/free-pro-team@latest/rest/reference/users#list-public-ssh-keys-for-the-authenticated-user

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage(){
    cat <<EOF
Fetches the currently authenticated GitHub user's public SSH key(s) via the GitHub API

SSH Keys can be found in the Web UI here:

    https://github.com/settings/keys

If you get a 404 error it is likely that your \$GITHUB_TOKEN doesn't have the read:public_key permission
You can edit the permissions your token has here:

    https://github.com/settings/tokens

To get other named users's public SSH keys see:

    github_ssh_get_user_public_keys.sh


${0##*/}
EOF
    exit 3
}

for arg; do
    case "$arg" in
        *)  usage
            ;;
    esac
done

echo "# Getting user login for tagging the keys" >&2
user="$("$srcdir/github_api.sh" "/user" | jq -r '.login')"

# XXX: not handling paging because if you have > 100 SSH keys I want to know what is going on first!

echo "# Fetching SSH Public Key(s) from GitHub for the currently authenticated account" >&2
echo "#" >&2
"$srcdir/github_api.sh" "/user/keys" |
# doesn't give any more info
#jq -r '.[].id' |
#while read -r id; do
#    "$srcdir/github_api.sh" "/user/keys/$id" |
#    jq .
#done
jq -r '.[] | [.key, .title] | @tsv' |
tr '\t' ' ' |
sed "s|$| (github.com/$user)|"
