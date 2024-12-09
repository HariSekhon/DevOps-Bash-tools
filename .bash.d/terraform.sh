#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-09-24 18:02:04 +0100 (Thu, 24 Sep 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# ============================================================================ #
#                               T e r r a f o r m
# ============================================================================ #

if ! [ -e ~/.tfenv/bin ] && is_mac; then
    mkdir -p -v ~/.tfenv
    tfenv_bin="$(find /usr/local/Cellar/tfenv -type d -name bin 2>/dev/null | head -n1)"
    if [ -d "$tfenv_bin" ]; then
        ln -sfv -- "$tfenv_bin" ~/.tfenv/bin
    fi
fi

add_PATH ~/.tfenv/bin

# don't get this wrong or you'll get this error:
#
#   ERRO[0000] fork/exec /Users/hari/.tfenv/bin: no such file or directory
#   ERRO[0000] Unable to determine underlying exit code, so Terragrunt will exit with error code 1
#
if [ -x ~/.tfenv/bin/terraform ]; then
    #export TERRAGRUNT_TFPATH=~/.tfenv/bin/  # it's full path to binary executable not a search $PATH!
    # neweer versions of Mac seems to not create ~/.tfenv/bin/ terraform link and instead use /opt/homebrew/bin/terraform link to the tfenv Cellar path
    export TERRAGRUNT_TFPATH=~/.tfenv/bin/terraform
elif ! [ -x "$TERRAGRUNT_TFPATH" ]; then
    unset TERRAGRUNT_TFPATH
fi

alias tf=terraform
alias tfp='tf plan'
alias tfa='tf apply'
alias tfip='tf init && tfp'
alias tfia='tf init && tfa'
alias tfaa='tfa -auto-approve'
alias tfiaa='tfia -auto-approve'
#complete -C /Users/hari/bin/terraform terraform

alias tffu='tf force-unlock -force'
# self-determine the lock
tffuu(){
    local lock_id
    lock_id="$(terraform plan -input=false -no-color 2>&1 | grep -A 1 'Lock Info:' | awk '/ID:/{print $2}')"
    terraform force-unlock -force "$lock_id"
}

alias tg=terragrunt
alias tgp='tg plan'
alias tga='tg apply'
alias tgaa='tga -auto-approve'
alias tgip='tg init && tgp'
alias tgia='tg init && tga'

if [ -n "${github:-}" ]; then
    for x in terraform-templates terraform tf; do
        if [ -d "$github/$x" ]; then
            # shellcheck disable=SC2139
            alias tft="cd '$github/$x'"
            break
        fi
    done
fi

#generate_terraform_autocomplete(){
#    local terraform_bin
#    local terraform_version_number
#
#    for terraform_bin in ~/bin/terraform[[:digit:]]*; do
#        [ -x "$terraform_bin" ] || continue
#        terraform_version_number="${terraform_bin##*/terraform}"
#        # expand now
#        # shellcheck disable=SC2139,SC2140
#        alias "tf${terraform_version_number}"="$terraform_bin"
#        complete -C "$terraform_bin" terraform
#        complete -C "$terraform_bin" tf
#    done
#
#    terraform_bin="$(type -P terraform)"
#    complete -C "$terraform_bin" terraform
#    complete -C "$terraform_bin" tf
#}
#
#generate_terraform_autocomplete
