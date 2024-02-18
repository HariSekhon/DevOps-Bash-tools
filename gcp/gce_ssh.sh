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
Runs 'gcloud compute ssh' to a VM while auto-determining its zone to make it easier to script iterating through VMs

You should either set your GCP project and region should already be in your current 'gcloud config',
or export CLOUDSDK_CORE_PROJECT and CLOUDSDK_CORE_REGION environment variables,
or supply --project ... and --region ... arguments

Requires GCloud SDK to be installed, configured and authenticated
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<vm_name> [<gcloud_sdk_args>]"

help_usage "$@"

min_args 1 "$@"

vm_name="$1"
shift || :

zone="$(gcloud compute instances list | awk "/^${vm_name}[[:space:]]/ {print \$2}")"

if [ -z "$zone" ]; then
    die "Failed to determine zone for VM name '$vm_name' - perhaps VM name is incorrect or wrong region or "
fi

gcloud compute ssh "$vm_name" --zone "$zone" "$@"
