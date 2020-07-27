#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  shellcheck disable=SC2139
#
#  Author: Hari Sekhon
#  Date: 2014-07-13 16:56:14 +0100
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# ============================================================================ #
#                                 A n s i b l e
# ============================================================================ #

bash_tools="${bash_tools:-$(dirname "${BASH_SOURCE[0]}")/..}"

# shellcheck disable=SC1090
type add_PATH &>/dev/null || . "$bash_tools/.bash.d/paths.sh"

# env var takes preference, then cwd, then $HOME, then /etc/ansible/ansible.cfg
# $srcdir set in .bashrc
# shellcheck disable=SC2154
export ANSIBLE_CONFIG="$bash_tools/.ansible.cfg"

if [ -n "${ANSIBLE_HOME:-}" ]; then
    add_PATH PYTHONPATH "$ANSIBLE_HOME/lib"
    add_PATH ANSIBLE_LIBRARY "$ANSIBLE_HOME/library"
    # resets man search path, breaking man lookups
    #add_PATH MANPATH "$ANSIBLE_HOME/docs/man"
fi

if [ -f ~/etc/ansible/hosts ]; then
    export ANSIBLE_HOSTS=~/etc/ansible/hosts
fi

# set in ~/.ansible.cfg now
#export ANSIBLE_HOST_KEY_CHECKING=False

# -D diff switch requires newish ansible, doesn't work on 1.7
# -b - matter of preference between using lots of sudo in manifests or not, better to remove it for tighter authz & logging purposes in governed environments
ansible_opts="-D -b"

alias a=ansible
# expand now, no dynamic surprises
alias ansible="ansible $ansible_opts"
alias ansible_playbook="ansible-playbook $ansible_opts"
#alias ansible_playbook_vault="ansible-playbook $ansible_opts --ask-vault-pass"
alias ansible_playbook_vault="ansible-playbook $ansible_opts --vault-id '$bash_tools/vault_pass.sh'"
