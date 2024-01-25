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
Fetches a GitHub user's public SSH key(s) via HTTP

User can be given as first argument, or environment variables \$GITHUB_USER or \$USER

Technically should use the GitHub API, see instead:  github_ssh_get_user_public_keys.sh


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


echo "# Fetching SSH Public Key(s) from GitHub for account:  $user" >&2
echo "#" >&2
curl -sS --fail "https://github.com/$user.keys" |
sed "s|$| github.com/$user|"
