#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-08-12 01:07:03 +0100 (Mon, 12 Aug 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -u
[ -n "${DEBUG:-}" ] && set -x

# source vault_pass.sh to load cred to environment for multiple ansible_playbook_vault runs without having to enter password each time
if [ -n "${PS1:-}" ]; then
    read -s -r -p "password: " VAULT_PASS
else
    # retuns password from environment to ansible_playbook_vault
    echo "${VAULT_PASS:-}"
fi
