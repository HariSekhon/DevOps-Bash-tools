#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-07-28 12:54:35 +0100 (Thu, 28 Jul 2022)
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
Creates a GCP firewall rule to permit kubeseal to communicate with sealed-secrets-controller service

Determines a given GKE cluster's master cidr block, network and target tags

https://github.com/bitnami-labs/sealed-secrets/blob/main/docs/GKE.md
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<project> <cluster_name>"

help_usage "$@"

num_args 2 "$@"

# project must be given explicitly to fix all subsequent gcloud commands to the right cluster to avoid concurrency race conditions of any other scripts or commands in adjacent windows from switching configs and causing these commands to go to the wrong project
project="$1"
cluster_name="$2"

PORT=8080

firewall_rule_name="gke-$cluster_name-masters-to-kubeseal"

export CLOUDSDK_CORE_PROJECT="$project"

timestamp "Getting details for cluster '$cluster_name'"
master_ipv4_cidr="$(gcloud container clusters describe "$cluster_name" --format='get(privateClusterConfig.masterIpv4CidrBlock)')"
network="$(gcloud container clusters describe "$cluster_name" --format='value(networkConfig.network.basename())')"
echo
echo "Determined cluster '$cluster_name' master cidr block to be '$master_ipv4_cidr'"
echo "Determined cluster '$cluster_name' network to be '$network'"
echo

timestamp "Listing firewall rules for cluster '^gke-$cluster_name':"
echo
gcloud compute firewall-rules list \
                                --filter "name~^gke-$cluster_name" \
                                --format 'table(
                                    name,
                                    network,
                                    direction,
                                    sourceRanges.list():label=SRC_RANGES,
                                    allowed[].map().firewall_rule().list():label=ALLOW,
                                    targetTags.list():label=TARGET_TAGS
                                )'
echo

timestamp "Getting target tags"
target_tags="$(gcloud compute firewall-rules list --filter "name~^gke-$cluster_name" --format 'get(targetTags.list())' | sort -u)"

timestamp "Determined target tags to be:"
echo
echo "$target_tags"
echo

if gcloud compute firewall-rules list --filter "name=$firewall_rule_name" --format 'get(name)' | grep -q .; then
    echo "GCP firewall rule '$firewall_rule_name' for kubeseal already exists. If this is not working for you, check the target tags, port etc haven't changed"
else
    timestamp "Adding a GCP firewall from master called '$firewall_rule_name' to permit IPv4 cidr '$master_ipv4_cidr' network '$network' to target tags '$target_tags'"
    gcloud compute firewall-rules create "$firewall_rule_name" \
                                         --network "$network" \
                                         --allow "tcp:$PORT" \
                                         --source-ranges "$master_ipv4_cidr" \
                                         --target-tags "$target_tags" \
                                         --priority 1000
    echo
    echo "Done"
fi
