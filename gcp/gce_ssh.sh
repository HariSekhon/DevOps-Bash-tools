#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-02-18 06:44:52 +0000 (Sun, 18 Feb 2024)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Runs 'gcloud compute ssh' to a VM while auto-determining its zone first to override any inherited zone config and make it easier to script iterating through VMs

Otherwise if \$CLOUDSDK_COMPUTE_ZONE environment is inherited (eg. via .envrc) pointing to a different zone it results in this error:

    ERROR: (gcloud.compute.ssh) Could not fetch resource:
     - The resource 'projects/<MY_PROJECT>/zones/<ZONE>/instances/<VM_NAME>' was not found

or if in the wrong project or region you can be interactively prompted for a zone

Your GCP project and region should already be set in your current 'gcloud config',
or export CLOUDSDK_CORE_PROJECT and CLOUDSDK_CORE_REGION environment variables,
or supply explicit --project ... and --region ... arguments to this script

If the VM zone isn't found it resolves the project and region to remind you that you're probably in the wrong project / region
while displaying them to make it more obvious that you've inherited the wrong config, to save you some debugging time
and stopping you from getting stuck on the interactive zone prompt

Example iteration if you don't have direct access or SSH keys to a client's VMs,
you can use this to SSH for loop like so using the standard gcloud compute ssh argument of '--command':

    for x in {1..10}; do gce_ssh.sh vm-\$x --command 'sudo systemctl restart MYAPP.service'; echo; done

You can also use an IP address of the VM for convenience which will get resolved to a VM name

Requires GCloud SDK to be installed, configured and authenticated
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<vm_name_or_ip> [<gcloud_sdk_args>]"

help_usage "$@"

min_args 1 "$@"

vm_name="$1"
shift || :

unset CLOUDSDK_COMPUTE_ZONE

if [[ "$vm_name" =~ ^[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+$ ]]; then
    ip="$vm_name"
    timestamp "Resolving IP '$ip' to VM name"
    vm_name="$(gcloud compute instances list --filter="networkInterfaces[0].networkIP: $ip" --format='value(name)')"
    if [ -z "$vm_name" ]; then
        die "Failed to resolve '$ip' to VM name"
    fi
fi

# If gcloud config's compute/zone is set, then actively determines the zone of the VM first and overrides it specifically
# Better to let it try to figure it out and exit with an explicit error reminding what project and region you are in
#if gcloud config get compute/zone 2>/dev/null | grep -q .; then
    timestamp "Determining zone for VM '$vm_name'"
    #zone="$(gcloud compute instances list | awk "/^${vm_name}[[:space:]]/ {print \$2}")"
    zone="$(gcloud compute instances list --filter="name=$vm_name" --format='value(zone)')"
    if [ -z "$zone" ]; then
        die "Failed to determine zone for VM name '$vm_name' - perhaps VM name is incorrect?
or wrong project ('$(gcloud config get core/project 2>/dev/null)')?
or wrong region ('$(gcloud config get compute/region 2>/dev/null)')?"
    fi
#fi

# would auto-determine the zone if in the right project and region but otherwise will interactively prompt
# - this is why we auto-populate the zone above to give a very explicit error out while showing the currently inherited project and region
timestamp "gcloud compute ssh '$vm_name' ${zone:+--zone "'$zone'"} $*"
gcloud compute ssh "$vm_name" ${zone:+--zone "$zone"} "$@"
