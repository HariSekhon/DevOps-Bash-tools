#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-08-12 01:07:03 +0100 (Mon, 12 Aug 2019)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Usage:
#
#   source vault_pass.sh
#
# to load cred to environment for multiple ansible_playbook_vault runs without having to enter password each time
#
# See Also:
#
#   the pass() function in .bash.d/functions.sh

set -u
[ -n "${DEBUG:-}" ] && set -x

if [ -n "${PS1:-}" ]; then
    #read -s -r -p "password: " VAULT_PASS
    prompt="Enter password: "
    password=""
    while IFS= read -p "$prompt" -r -s -n 1 char; do
        if [[ "$char" == $'\0' ]]; then
            break
        fi
        prompt='*'
        password="${password}${char}"
    done
    echo
    export VAULT_PASS="$password"
    echo "exported \$VAULT_PASS"
    echo "ready to be called from ansible --vault-id"
elif [ -n "${VAULT_PASS:-}" ]; then
    # retuns password from environment to ansible_playbook_vault
    echo "$VAULT_PASS"
else
    echo "\$VAULT_PASS not defined - did you forget to define it? Source $0 interactively to set it" >&2
    exit 1
fi
