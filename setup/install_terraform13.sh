#!/usr/bin/env bash
#
#  Author: Hari Sekhon
#  Date: 2019/09/20
#
#  https://github.com/harisekhon/devops-bash-tools
#
#  License: see accompanying LICENSE file
#
#  https://www.linkedin.com/in/harisekhon
#

# Installs Terraform 0.14 on Mac / Linux
#
# If running as root, installs to /usr/local/bin/terraform14
#
# If running as non-root, installs to $HOME/bin/terraform14
#
# Useful because I often have to fix Terraform environments with 0.13 upgrade, so can't just install latest 0.14 version which doesn't have the command

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

VERSIONED_INSTALL=1 TERRAFORM_VERSION=0.13.6 "$srcdir/install_terraform.sh"
