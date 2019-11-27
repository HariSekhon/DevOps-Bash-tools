#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  shellcheck disable=SC1090
#
#  Author: Hari Sekhon
#  Date: 2019-11-14 22:22:35 +0000 (Thu, 14 Nov 2019)
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
#              G C P  -  G o o g l e   C l o u d   P l a t f o r m
# ============================================================================ #

srcdir="${srcdir:-$(dirname "${BASH_SOURCE[0]}")/..}"

# shellcheck disable=SC1090
type add_PATH &>/dev/null || . "$srcdir/.bash.d/paths.sh"

# adds GCloud CLI tools to $PATH
if [ -f ~/google-cloud-sdk/path.bash.inc ]; then
    source ~/google-cloud-sdk/path.bash.inc
fi

# Bash completion for GCloud CLI tools
if [ -f ~/google-cloud-sdk/completion.bash.inc ]; then
    source ~/google-cloud-sdk/completion.bash.inc
fi

alias gce="gcloud compute"
alias gke="gcloud container clusters"
alias gc="gcloud container"
alias gbs="gcloud builds submit --tag"
