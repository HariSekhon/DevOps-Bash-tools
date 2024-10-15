#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-10-15 06:15:47 +0400 (Tue, 15 Oct 2024)
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
Enables and fetches AWS EKS Master logs via CloudWatch

If CloudWatch logging hasn't been enabled already for this EKS cluser's master components, enabling it will take some time and the script will fail to get the log groups because they won't exist yet or you'll get an error like this:

    An error occurred (ResourceNotFoundException) when calling the DescribeLogStreams operation: The specified log group does not exist.

Or this:

    An error occurred (ResourceInUseException) when calling the UpdateClusterConfig operation: Cannot LoggingUpdate because cluster EKS_CLUSTER_NAME currently has update be92dbc8-8406-3188-b1c8-afd40aa3c785 in progress

Wait a while and then run it again

$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<EKS_CLUSTER_NAME> [<log_line_limit_per_service>]"

help_usage "$@"

min_args 1 "$@"
max_args 2 "$@"

eks_cluster="$1"
limit="${2:-10000}"

#aws eks update-cluster-config --name "$eks_cluster" \
#        --logging '{"clusterLogging":[{"types":["api","audit","authenticator","scheduler","controllerManager"],"enabled":true}]}'

timestamp "Enabling CloudWatch logging on EKS cluster; $eks_cluster"
aws eks update-cluster-config --name "$eks_cluster" \
        --logging '{
            "clusterLogging":[
                {
                    "types": [
                        "api",
                        "audit",
                        "authenticator",
                        "scheduler",
                        "controllerManager"
                    ],
                    "enabled":true
                }
            ]
        }' || :
echo

timestamp "Log Groups:"
echo
aws logs describe-log-groups --log-group-name-prefix "/aws/eks/$eks_cluster/cluster"
echo

#for service in kube-apiserver kube-scheduler kube-controller-manager; do
for service in kube-apiserver; do

    timestamp "Getting log stream name for service: $service"
    echo
    log_stream="$(aws logs describe-log-streams --log-group-name "/aws/eks/$eks_cluster/cluster")"
    timestamp "Determined log stream to be: $log_stream"
    echo

    timestamp "Getting logs for: $service"
    aws logs get-log-events --log-group-name "/aws/eks/$eks_cluster/cluster/kube-apiserver" --log-stream-name "$log_stream" --limit "$limit"
    echo

done
