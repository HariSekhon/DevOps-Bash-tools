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

#complete -C /Users/hari/bin/terraform terraform
terraform_bin="$(type -P terraform)"
complete -C "$terraform_bin" terraform
complete -C "$terraform_bin" tf
