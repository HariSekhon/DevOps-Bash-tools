#!/usr/bin/env bash
#
#  Author: Hari Sekhon
#  Date: 2019-09-16
#
#  https://github.com/harisekhon/devops-bash-tools
#
#  License: see accompanying LICENSE file
#
#  https://www.linkedin.com/in/harisekhon
#

# Installs the SSH Key(s) from user's GitHub to the local $HOME/.ssh/authorized_keys
#
# Uses $GITHUB_USER or $USER as the expected GitHub user
#
# set $AUTHORIZED_KEYS to specify an alternative ssh keys location

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

home="${HOME:-$(cd && pwd)}"
authorized_keys="${AUTHORIZED_KEYS:-$home/.ssh/authorized_keys}"

while read -r ssh_key; do
    # skip comment lines
    [ -z "$(sed 's/#.*//; /^[[:space:]]*$/d' <<< "$ssh_key")" ] && continue
    echo "Processing key:  $ssh_key"
    #algo_hash="$(awk '{print $1" "$2}' <<< "$ssh_key")"
    algo_hash="${ssh_key%%==*}"
    if [ -f "$authorized_keys" ] &&
        grep -Fq "$algo_hash" "$authorized_keys"; then
        echo "Key already found in $authorized_keys, skipping..."
    else
        echo "Adding key to $authorized_keys"
        mkdir -vp "$(dirname "$authorized_keys")"
        echo "$ssh_key from GitHub" >> "$authorized_keys"
    fi
    echo
    echo "ensuring correct 0600 permissions applied to $authorized_keys"
    chmod 0600 "$authorized_keys"
    echo
done < <("$srcdir/../github_get_user_ssh_public_keys.sh")
echo Done
