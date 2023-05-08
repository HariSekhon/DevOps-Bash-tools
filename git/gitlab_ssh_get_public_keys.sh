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

# https://docs.gitlab.com/ee/api/users.html#list-ssh-keys

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage(){
    cat <<EOF
Fetches the currently authenticated GitLab user's public SSH key(s) via the GitLab API

SSH Keys can be found in the Web UI here:

    https://gitlab.com/profile/keys

If you get a 404 error it is likely that your \$GITLAB_TOKEN doesn't have the 'read_api' or 'api' (full) permissions
You can regenerate a token with the right permissions here:

    https://gitlab.com/profile/personal_access_tokens

To get other named users's public SSH keys see:

    gitlab_ssh_get_user_public_keys.sh


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

# XXX: not handling paging because if you have > 100 SSH keys I want to know what is going on first!

echo "# Fetching SSH Public Key(s) from GitLab for currently authenticated account" >&2
echo "#" >&2
# authenticated query
"$srcdir/gitlab_api.sh" "/user/keys" |
jq -r '.[] | [.key, .title] | @tsv'
