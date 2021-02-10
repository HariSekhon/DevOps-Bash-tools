#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-09-24 18:02:04 +0100 (Thu, 24 Sep 2020)
#
#  https://github.com/HariSekhon/bash-tools
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

alias tf=terraform
alias tfp='tf plan'
alias tfa='tf apply'
#complete -C /Users/hari/bin/terraform terraform

generate_terraform_autocomplete(){
    local terraform_bin
    local terraform_version_number

    for terraform_bin in ~/bin/terraform[[:digit:]]*; do
        [ -x "$terraform_bin" ] || continue
        terraform_version_number="${terraform_bin##*/terraform}"
        # expand now
        # shellcheck disable=SC2139,SC2140
        alias "tf${terraform_version_number}"="$terraform_bin"
        complete -C "$terraform_bin" terraform
        complete -C "$terraform_bin" tf
    done

    terraform_bin="$(type -P terraform)"
    complete -C "$terraform_bin" terraform
    complete -C "$terraform_bin" tf
}

generate_terraform_autocomplete
