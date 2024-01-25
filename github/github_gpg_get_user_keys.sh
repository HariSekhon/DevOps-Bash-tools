#!/usr/bin/env bash
#
#  Author: Hari Sekhon
#  Date: 2020-08-17 09:32:20 +0100 (Mon, 17 Aug 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying LICENSE file
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://docs.github.com/en/rest/reference/users#list-gpg-keys-for-a-user

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

usage(){
    cat <<EOF
Fetches a GitHub user's public GPG key(s) via the GitHub API

User can be given as first argument, or environment variables \$GITHUB_USER or \$USER

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

echo "# Fetching GPG Public Key(s) from GitHub for account:  $user" >&2
echo "#" >&2
curl -sS --fail "https://api.github.com/users/$user/gpg_keys" |
jq -r '.[].public_key'
