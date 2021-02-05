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

# Installs Terraform 0.12 on Mac / Linux
#
# If running as root, installs to /usr/local/bin/terraform12
#
# If running as non-root, installs to $HOME/bin/terraform12
#
# Useful to quickly align to run on a given environment

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

VERSIONED_INSTALL=1 TERRAFORM_VERSION=0.12.29 "$srcdir/install_terraform.sh"
