#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-04-10 13:02:46 +0100 (Fri, 10 Apr 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

if type -P direnv &>/dev/null; then
    if ! type _direnv_hook &>/dev/null ||
       ! [[ "${PROMPT_COMMAND:-}" =~ _direnv_hook ]]; then
        eval "$(direnv hook bash)"
    fi
fi

# direnv seems to inserts a double semi-colon which breaks PROMPT_COMMAND
#export PROMPT_COMMAND="${PROMPT_COMMAND%%;;*}"
export PROMPT_COMMAND="${PROMPT_COMMAND//;;/;}"

#alias envrc='$EDITOR .envrc && direnv allow .'
# same effect as above
alias envrc='direnv edit'

# allow all .envrc under your current root - use only inside trusted repos
alias direnvallowall='find . -name .envrc -exec direnv allow {} \;'
alias da='direnv allow'
alias daa='direnvallowall'
