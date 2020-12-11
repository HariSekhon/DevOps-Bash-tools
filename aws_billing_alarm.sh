#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-12-11 16:30:33 +0000 (Fri, 11 Dec 2020)
#
#  https://github.com/HariSekhon/bash-tools
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

# shellcheck disable=SC1090
. "$srcdir/lib/aws.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Sets an AWS Billing Alarm as soon as you begin incurring any charges

The alarm is set in the us-east-1 region (N. Virginia in the web console) because that is where the metric is stored for all accounts currently, regardless of which region you're actually using

If you give an argument, will set the alert threshold to that amount of USD - an alarm is raised once it goes above that amount

The default threshold amount is 0.00 USD to alert on any charges for safety


See the created alarm here:

    https://console.aws.amazon.com/cloudwatch/home?region=us-east-1

(notice the region must be us-east-1)


$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<threshold_amount_in_USD>"

help_usage "$@"

threshold="${1:-0.00}"

if ! [[ "$threshold" =~ ^[[:digit:]]{1,4}(\.[[:digit:]]{1,2})?$ ]]; then
    usage "invalid threshold argument given - must be 0.01 - 9999.99 USD"
fi

# --period 21600 = 6 hours (default)
aws cloudwatch put-metric-alarm --alarm-name "AWS Charges" \
                                --alarm-description "Alerts on AWS charges greater than $threshold USD" \
                                --actions-enabled \
                                --region us-east-1 \
                                --namespace "AWS/Billing" \
                                --metric-name "EstimatedCharges" \
                                --threshold "$threshold" \
                                --comparison-operator "GreaterThanThreshold" \
                                --statistic Maximum \
                                --period 21600 \
                                --evaluation-periods 1
