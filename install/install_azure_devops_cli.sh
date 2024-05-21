#!/usr/bin/env bash
# vim:ts=4:sts=4:sw=4:et
# shellcheck disable=SC2230
# command -v catches aliases, not suitable
#
#  Author: Hari Sekhon
#  Date: 2020-03-06 17:38:12 +0000 (Fri, 06 Mar 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying LICENSE file
#
#  https://www.linkedin.com/in/HariSekhon
#

# Installs Azure CLI
#
# https://learn.microsoft.com/en-us/azure/devops/cli/?view=azure-devops

# XXX: Note - as of May 2024 Azure DevOps CLI only supports the cloud not the on premise server

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing Azure DevOps CLI"
echo

"$srcdir/install_azure_cli.sh"
echo

echo "Installing Azure DevOps CLI Extension"
az extension add --name azure-devops
echo

echo "Checking Azure DevOps CLI Extension is installed"
az extension show --name azure-devops
echo

echo "Azure DevOps CLI extension installation complete"
echo

echo "Next step configure your default organization and project to avoid having to specify it in each command"
echo
echo "Example:"
echo
echo "  az devops configure --defaults organization=https://dev.azure.com/harisekhon project=GitHub"
echo
echo "Show configuration:"
echo
echo "  az devops configure -l"
