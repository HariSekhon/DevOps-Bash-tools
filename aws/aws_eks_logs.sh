#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-10-15 04:58:14 +0400 (Tue, 15 Oct 2024)
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
. "$srcdir/lib/aws.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Fetch logs from EKS EC2 VMs for support debug requests by vendors

Uses the adjacent script:

	$srcdir/../monitoring/ssh_dump_logs.sh

Requires Kubectl to be installed and configured to be on the right AWS cluster context as it uses this to determine the nodes

User - set your SSH_USER environment variable

SSH key - either set SSH_KEY to the EC2 pem key or add it to a local ssh-agent for passwordless authentication to work

See here for details:

	$srcdir/../monitoring/ssh_dump_logs.sh --help
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

num_args 0 "$@"

#eks_node_groups=$(aws eks list-nodegroups --cluster-name "$EKS_CLUSTER" --query 'nodegroups' --output text)
#
#for node_group in $eks_node_groups; do
#    instance_ids=$(aws eks describe-nodegroup --cluster-name "$EKS_CLUSTER" \
#                                              --nodegroup-name "$node_group" \
#                                              --query 'nodegroup.resources.autoScalingGroups[*].instances[*]' \
#                                              --output text)
#    aws ec2 describe-instances --instance-ids "$instance_ids" \
#                               --query 'Reservations[*].Instances[*].[InstanceId, Tags[?Key==`Name`].Value]' \
#                               --output text
#done

# simpler
timestamp "Getting Kubernetes nodes via kubectl"
nodes="$(kubectl top nodes --no-headers | awk '{print $1}')"
num_nodes="$(wc -l <<< "$nodes" | sed 's/[[:space:]]//g')"
timestamp "Found $num_nodes nodes"
echo

timestamp "SSH Keyscanning nodes to prevent getting stuck on host key pop-ups"
for node in $nodes; do
	timestamp "SSH keyscan '$node'"
	ssh-keyscan "$node" >> ~/.ssh/known_hosts
done
echo

# set the default EC2 user if nothing is set
SSH_USER="${SSH_USER:-ec2-user}"

# want splitting
# shellcheck disable=SC2046
"$srcdir/../monitoring/ssh_dump_logs.sh" $(for node in $nodes; do echo "ec2-user@$node"; done)
