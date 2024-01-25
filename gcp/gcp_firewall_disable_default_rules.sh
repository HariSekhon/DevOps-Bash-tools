#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-01-20 13:04:42 +0000 (Wed, 20 Jan 2021)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
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
Disables GCP default-allow-* rules in the default network as these are too lax permitting all of the internet to access VMs

Skips the default-allow-internal rule though to avoid breaking internal infrastructure connections, you'd have to change that yourself if wanted.

In reality you probably shouldn't be using the default network anyway, and disabling these rules is just good practice to tighten up your GCP configuration.


GCP Firewall Documentation:

    https://cloud.google.com/vpc/docs/firewalls#more_rules_default_vpc


Requires GCloud SDK to be installed and configured to the right project
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

gcloud compute firewall-rules list --filter 'name: default-allow-* AND network: default' --format='value(name)' |
grep -v '^default-allow-internal$'  |
while read -r firewall_rule_name; do
    timestamp "disabling firewall-rule $firewall_rule_name"
    gcloud compute firewall-rules update --disabled "$firewall_rule_name"
    echo
done
