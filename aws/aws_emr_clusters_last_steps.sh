#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-01-02 17:56:07 +0700 (Thu, 02 Jan 2025)
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
Shows the last N steps executed on each EMR cluster and their EndTime to find idle clusters that should be removed

Also checks CloudWatch for number of steps running within the last few months to catch directly submitted jobs such as
Spark, Hive, Glue or Athena which won't show up in the native steps list

You can also check this via the Monitoring tab graphs for the cluster by setting the date range further back


$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<last_N_steps>]"

help_usage "$@"

max_args 1 "$@"

num_steps="${1:-5}"

if ! is_int "$num_steps"; then
    usage "Number of steps argument must be an integer"
fi

if [ "$num_steps" = 0 ]; then
    usage "Number of steps cannot be zero"
fi

timestamp "Fetching list of EMR clusters"
cluster_ids=$(aws emr list-clusters --query 'Clusters[*].Id' --output text)

if is_blank "$cluster_ids"; then
    die "No EMR clusters found"
fi

timestamp "Fetching the last $num_steps steps for each EMR cluster..."
echo

start_date=$(date -u --date="1 year ago" +"%Y-%m-%dT%H:%M:%SZ")
end_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

for cluster_id in $cluster_ids; do
    aws emr describe-cluster \
        --cluster-id "$cluster_id" \
        --query 'Cluster.{
            "ID": Id,
            "Name": Name,
            "Status": Status.State
        }' \
        --output table || {
            warn "Failed to describe cluster $cluster_id, skipping..."
            continue
    }

    # don't want backtick shell expansion inside AWS --query
    # shellcheck disable=SC2016
    steps="$(
        aws emr list-steps --cluster-id "$cluster_id" \
            --query 'Steps[?Status.Timeline.EndDateTime != `null`]|[].{Name:Name,EndTime:Status.Timeline.EndDateTime}' \
            --output json |
        jq -r "
            . |
            sort_by(.EndTime) |
            reverse |
            .[:$num_steps] |
            .[] |
            [.Name, .EndTime] |
            @tsv
        "
    )"


    if is_blank "$steps"; then
        timestamp "No steps found for this cluster"
    else
        timestamp "Last 5 steps for cluster:"
        echo >&2
        printf "    %-50s %s\n" "Step Name" "End Time"
        echo "    -------------------------------------------------- --------------------------------"
        while IFS=$'\t' read -r step_name end_time; do
            printf "    %-50s %s\n" "$step_name" "$end_time"
        done <<< "$steps"
    fi
    echo >&2

    # Get list of metrics to query like this:
    #
    #   aws cloudwatch list-metrics --namespace "AWS/ElasticMapReduce" --dimensions Name=JobFlowId,Value="$cluster_id"
    #
    timestamp "Apps Running within last $num_steps x 30 day periods"
    aws cloudwatch get-metric-statistics \
        --namespace "AWS/ElasticMapReduce" \
        --metric-name "AppsRunning" \
        --dimensions Name=JobFlowId,Value="$cluster_id" \
        --start-time "$start_date" \
        --end-time "$end_date" \
        --period $((86400 * 30)) \
        --statistics Sum \
        --query 'Datapoints[*].[Timestamp,Sum]' \
        --output json |
    jq -r "sort_by(.[0]) | reverse | .[:$num_steps][] | @tsv"

    echo >&2
    echo >&2
done
