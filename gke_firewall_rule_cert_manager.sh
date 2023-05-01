#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-12-15 12:21:25 +0000 (Tue, 15 Dec 2020)
#
#  https://github.com/HariSekhon/work
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
Creates a GCP firewall rule to permit Cert Manager access on port 10250 for the admission webhook

Determines a given GKE cluster's master cidr block, network and target tags

Solves this error:

    Internal error occurred: failed calling admission webhook ... the server is currently unable to handle the request
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<project> <cluster>"

help_usage "$@"

num_args 2 "$@"

# project must be given explicitly to fix all subsequent gcloud commands to the right cluster to avoid concurrency race conditions of any other scripts or commands in adjacent windows from switching configs and causing these commands to go to the wrong project
project="$1"
cluster_name="$2"

PORT=10250

firewall_rule_name="gke-$cluster_name-masters-to-cert-manager"

export CLOUDSDK_CORE_PROJECT="$project"

timestamp "Getting details for cluster '$cluster_name'"
#gcloud container clusters describe "$cluster"
master_cidr_block="$(gcloud container clusters describe "$cluster_name" --format='get(privateClusterConfig.masterIpv4CidrBlock)')"
network="$(gcloud container clusters describe "$cluster_name" --format='value(networkConfig.network.basename())')"
echo
echo "Determined cluster '$cluster_name' master cidr block to be '$master_cidr_block'"
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
    timestamp "GCP firewall rule '$firewall_rule_name' for cert manager already exists. If this is not working for you, check the target tags, port etc haven't changed"
else
    timestamp "Adding a GCP firewall rule called '$firewall_rule_name' to permit GKE cluster '$cluster_name' master nodes to access cert manager pods on port $PORT:"
    gcloud compute firewall-rules create "$firewall_rule_name" \
                                           --network "$network" \
                                           --action ALLOW \
                                           --direction INGRESS \
                                           --source-ranges "$master_cidr_block" \
                                           --rules TCP:"$PORT" \
                                           --target-tags "$target_tags"  # is one in my testing, might need editing if more than one
    echo
    echo "Done."
fi
