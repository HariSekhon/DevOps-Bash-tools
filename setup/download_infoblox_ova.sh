#!/usr/bin/env bash
# shellcheck disable=SC2230
#
#  Author: Hari Sekhon
#  Date: early 2019
#
#  https://github.com/harisekhon/devops-bash-tools
#
#  License: see accompanying LICENSE file
#
#  https://www.linkedin.com/in/harisekhon
#

# Download InfoBlox DDI OVA and calls it to trigger the import to VirtualBox pop up

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

INFOBLOX_URL=https://go.infoblox.com/downloads/vnios/8.4.4/nios-8.4.4-386831-2019-08-02-03-45-48-ddi.ova

echo "Downloading InfoBlox OVA to ~/Downloads/"

cd ~/Downloads/

infoblox_ova="${INFOBLOX_URL##*/}"

if ! [ "$infoblox_ova" ]; then
    wget "$INFOBLOX_URL"
fi

if [ "$(uname -s)" = Darwin ]; then
    echo "Opening $infoblox_ova, will run import in GUI and prompt you to accept license agreement"
    open "$infoblox_ova"
else
    echo "Load $PWD/$infoblox_ova to VirtualBox - you will be prompted to accept license agreement"
    # vboxmanage import nios-8.4.4-386831-2019-08-02-03-45-48-ddi.ova
    #VBoxManage: error: Cannot import until the license agreement listed above is accepted.
fi
