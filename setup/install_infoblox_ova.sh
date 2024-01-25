#!/usr/bin/env bash
# shellcheck disable=SC2230,SC2317
#
#  Author: Hari Sekhon
#  Date: early 2019
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying LICENSE file
#
#  https://www.linkedin.com/in/HariSekhon
#

# Download InfoBlox DDI OVA and calls it to trigger the import to VirtualBox pop up

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

echo "InfoBlox DDI doesn't boot when the specs are downsized to fit on a Mac. You would need to install the OVA to a full VMware with 128GB RAM etc"
echo "Rest of script will not execute, but the code is left for reference"

exit 1

INFOBLOX_URL=https://go.infoblox.com/downloads/vnios/8.4.4/nios-8.4.4-386831-2019-08-02-03-45-48-ddi.ova

VM_NAME="${VM_NAME:-VNIOS System}"

CPUS="${CPUS:-2}"
RAM="${RAM:-4096}"  # MB
VRAM="${VRAM:-12}"  # Video RAM MB

echo "Downloading InfoBlox OVA to ~/Downloads/"

cd ~/Downloads/

infoblox_ova="${INFOBLOX_URL##*/}"

if [ "$infoblox_ova" ]; then
    echo "Found $infoblox_ova, skipping download"
else
    wget "$INFOBLOX_URL"
fi

if vboxmanage list vms | grep "^\"$VM_NAME\""; then
    echo "$VM_NAME VM already found, skipping import"
else
    # vboxmanage import nios-8.4.4-386831-2019-08-02-03-45-48-ddi.ova
    #VBoxManage: error: Cannot import until the license agreement listed above is accepted.
    echo "Importing $infoblox_ova"
    # could set $VM_NAME here but want to leave it as the default import
    vboxmanage import --vsys 0 --vmname "$VM_NAME" --eula accept "$infoblox_ova"
fi

if vboxmanage showvminfo "$VM_NAME" | grep -q "^State:[[:space:]]*running"; then
    echo "VM already running, skipping configure and start"
else
    echo "Configuring $VM_NAME with $CPUS CPUs, $RAM MB RAM, $VRAM MB Video RAM"
    vboxmanage modifyvm "$VM_NAME" --cpus "$CPUS" --memory "$RAM" --vram "$VRAM"

    echo "Starting $VM_NAME"
    vboxmanage startvm "$VM_NAME"
fi
