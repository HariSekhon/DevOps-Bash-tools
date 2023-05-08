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

# https://docs.github.com/en/rest/reference/users#list-public-keys-for-a-user

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

usage(){
    cat <<EOF
Fetches a GitHub user's public SSH key(s) via the GitHub API

User can be given as first argument, otherwise falls back to using environment variables \$GITHUB_USER or \$USER

SSH Keys can be found in the Web UI here:

    https://github.com/settings/keys

To retrieve SSH keys with comments, you'd need to use API authentication, see

    github_ssh_get_public_keys.sh


${0##*/} <user>
EOF
    exit 3
}

for arg; do
    case "$arg" in
        -*)     usage
                ;;
    esac
done

if [ $# -gt 1 ]; then
    usage
elif [ $# -eq 1 ]; then
    user="$1"
elif [ -n "${GITHUB_USER:-}" ]; then
    user="$GITHUB_USER"
elif [ -n "${USER:-}" ]; then
    if [[ "$USER" =~ hari|sekhon ]]; then
        user=harisekhon
    else
        user="$USER"
    fi
else
    usage
fi

# XXX: not handling paging because if you have > 100 SSH keys I want to know what is going on first!

echo "# Fetching SSH Public Key(s) from GitHub for account:  $user" >&2
echo "#" >&2
curl -sS --fail "https://api.github.com/users/$user/keys" |
jq -r '.[].key' |
sed "s/$/ $user (github.com)/"
