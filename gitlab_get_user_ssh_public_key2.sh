#!/usr/bin/env bash
#
#  Author: Hari Sekhon
#  Date: 2020-08-16 18:25:33 +0100 (Sun, 16 Aug 2020)
#
#  https://github.com/harisekhon/devops-bash-tools
#
#  License: see accompanying LICENSE file
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

usage(){
    cat <<EOF
Fetches a GitLab user's public SSH key via HTTP

User can be given as first argument, or environment variables \$GITLAB_USER or \$USER

Technically should use the GitLab API instead as it's more guaranteed to be stable
See Also: gitlab_get_user_ssh_public_key_api.sh


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


echo "# Fetching SSH Public Key(s) from GitLab for account:  $user" >&2
echo "#" >&2
curl -sS --fail "https://gitlab.com/$user.keys"
