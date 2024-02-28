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
SSH keyscans all the GCE VM hosts that match the given regex filter to add them to SSH known_hosts

Useful to doing direct SSH to hosts and especially for Ansible to speed up not going through IAP which is slow
and not having them prompt to accept the SSH keys
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<regex_filter> <gcloud_cli_options>]"

help_usage "$@"

#max_args 1 "$@"

ssh_known_hosts_file=~/.ssh/known_hosts

"$srcdir/gce_host_ips.sh" "$@" |
while read -r ip hostname; do
    ssh-keyscan "$ip" >> "$ssh_known_hosts_file"
    ssh-keyscan "$hostname" >> "$ssh_known_hosts_file"
done
