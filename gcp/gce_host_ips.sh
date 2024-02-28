#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-02-28 12:40:41 +0000 (Wed, 28 Feb 2024)
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
Outputs the hostnames and IP addresses of all or a given regex filter of Google Compute Engine hosts
in the current project in a format that can be piped or copied into /etc/hosts

Useful to doing direct SSH to hosts and especially for Ansible to speed up not going through IAP which is slow


Output:

<ip>    <vm_hostname>
<ip>    <vm_hostname2>
<ip>    <vm_hostname3>


Used by gce_ssh_keyscan.sh which you might also want to use to pre-populate your SSH known_hosts
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<regex_filter> <gcloud_cli_options>]"

help_usage "$@"

#max_args 1 "$@"

regex="${1:-.*}"
shift || :

gcloud compute instances list --filter="name ~ $regex" --format='get(networkInterfaces[0].networkIP, name)' "$@" |
column -t |
sort -k2
