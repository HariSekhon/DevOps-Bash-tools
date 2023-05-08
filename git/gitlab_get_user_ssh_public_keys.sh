#!/usr/bin/env bash
#
#  Author: Hari Sekhon
#  Date: 2020-08-16 18:13:02 +0100 (Sun, 16 Aug 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying LICENSE file
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://docs.gitlab.com/ee/api/users.html#list-ssh-keys-for-user

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
#srcdir="$(dirname "${BASH_SOURCE[0]}")"

usage(){
    cat <<EOF
Fetches a given GitLab user's public SSH key(s) via the GitLab API

User can be given as first argument, otherwise falls back to using environment variables \$GITLAB_USER or \$USER

SSH Keys can be found in the Web UI here:

    https://gitlab.com/profile/keys


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
elif [ -n "${GITLAB_USER:-}" ]; then
    user="$GITLAB_USER"
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

echo "# Fetching SSH Public Key(s) from GitLab for account:  $user" >&2
echo "#" >&2
# authenticated query is not necessary, gets more information than GitHub regardless, which I use to add standard SSH key description suffix back (useful if loading these keys to other systems to know what their descriptions are)
curl -sS --fail "https://gitlab.com/api/v4/users/$user/keys" |
jq -r '.[] | [.key, .title] | @tsv' |
tr '\t' ' '
