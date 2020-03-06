#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  shellcheck disable=SC1090
#
#  Author: Hari Sekhon
#  Date: 2020-03-06 16:36:42 +0000 (Fri, 06 Mar 2020)
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
#                                   A z u r e
# ============================================================================ #

srcdir="${srcdir:-$(dirname "${BASH_SOURCE[0]}")/..}"

# shellcheck disable=SC1090
#type add_PATH &>/dev/null || . "$srcdir/.bash.d/paths.sh"

# assh is an alias to awless ssh
azssh(){
    local ip
    ip="$(az vm show --name "$1" -d --query "[publicIps]" -o tsv)"
    ssh azureuser@"$ip"
}
