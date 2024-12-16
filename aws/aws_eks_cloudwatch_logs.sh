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


For the EKS Node logs, use the adjacent script:

    aws_eks_ssh_dump_logs.sh


$usage_aws_cli_jq_required
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
log_groups="$(aws logs describe-log-groups --log-group-name-prefix "/aws/eks/$eks_cluster/cluster" |
    jq_debug_pipe_dump |
    jq -Mr '.logGroups[].logGroupName')"
echo "$log_groups"
echo

tstamp="$(date '+%F_%H%M%S')"

for log_group in $log_groups; do

    timestamp "Getting log stream names for log_group: $log_group"
    echo
    # usually this
    #log_stream="$(aws logs describe-log-streams --log-group-name "/aws/eks/$eks_cluster/cluster")"
    log_streams="$(aws logs describe-log-streams --log-group-name "$log_group" |
        jq_debug_pipe_dump |
        jq -Mr '.logStreams[].logStreamName'
    )"

    for log_stream in $log_streams; do
        timestamp "Getting logs for stream: $log_stream"
        logfile="${log_group//\//_}.${log_stream//\//_}.$tstamp.log"
        logfile="${logfile#_}"
        aws logs get-log-events --log-group-name "$log_group" --log-stream-name "$log_stream" --limit "$limit" |
        jq_debug_pipe_dump |
        #jq -Mr '.events[] | [.timestamp + "  " .message] | @tsv' > "$logfile"
        jq -Mr '.events[].message' > "$logfile"
        timestamp "Log stream dumped to file: $logfile"
        echo
    done
    echo

done

timestamp "Logs fetched, creating compressed tarball"
echo

tarball="$eks_cluster.master.cloudwatch.logs.$tstamp.tar.gz"

tar czvf "$tarball" "aws_eks_${eks_cluster}_"*".$tstamp.log"

echo
timestamp "Generated tarball: $tarball"
echo

timestamp "Completed download of AWS EKS CloudWatch Logs for cluster: $eks_cluster"
