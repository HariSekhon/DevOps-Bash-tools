#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: echo project id is {project_id}, VM name is '{name}', VM IP is '{ip}'
#
#  Author: Hari Sekhon
#  Date: 2024-02-20 15:14:12 +0000 (Tue, 20 Feb 2024)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
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
Run a command for each GCP VM instance in the current GCP project

This is powerful so use carefully!

Useful when combined with gce_ssh.sh using IAP to run some command on all instances

WARNING: do not run any command reading from standard input, otherwise it will consume the project id/names and exit after the first iteration

Requires GCloud SDK to be installed and configured and 'gcloud' to be in the \$PATH

The first argument is the VM Name or IP filter as an ERE regex to run against only those matching VMs

All remaining arguments become the command template

The following command template tokens are replaced in each iteration:

VM Name:      {name}  {vm_name}
VM IP:        {ip}    {vm_ip}
Project ID:   {project_id}

eg.
    ${0##*/} '.*' 'echo VM name {name} has ip {ip}'

"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<name_or_ip_filter_ERE> <command> <args>"

help_usage "$@"

min_args 2 "$@"

filter="$1"
shift || :

# for informational purposes in the header only
project_id="$(gcloud config list --format='get(core.project)')"

gcloud compute instances list --format='value(name,networkInterfaces[0].networkIP)' |
grep -E "$filter" |
while read -r name ip; do
    echo "# ============================================================================ #" >&2
    echo "# GCP Project $project_id -- VM Name = $name -- IP = $ip" >&2
    echo "# ============================================================================ #" >&2
    cmd=("$@")
    cmd=("${cmd[@]//\{project_id\}/$project_id}")
    cmd=("${cmd[@]//\{vm_name\}/$name}")
    cmd=("${cmd[@]//\{name\}/$name}")
    cmd=("${cmd[@]//\{vm_ip\}/$ip}")
    cmd=("${cmd[@]//\{ip\}/$ip}")
    # need eval'ing to able to inline quoted script
    # shellcheck disable=SC2294
    eval "${cmd[@]}"
    echo >&2
    echo >&2
done
