#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-12-11 16:30:33 +0000 (Fri, 11 Dec 2020)
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
. "$srcdir/lib/aws.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Sets an AWS CloudWatch billing alarm to trigger as soon as you begin incurring any charges

Creates an SNS topic and subscription for the given email address and links it to the above CloudWatch Alarm to email you as soon as your billing charges go over

The alarm is set in the us-east-1 region (N. Virginia in the web console) because that is where the metric billing data accumulates, regardless of which region you actually use


The first argument sets the alert threshold in USD - an alarm is raised once it goes above that amount
The default threshold is 0.00 USD to alert on any charges for safety

The second argument sets the email address to use in an SNS topic to notify you.
If no email is given specified attempts to use the email from your local Git configuration.
If neither is available, shows this usage mesage.

XXX: You must also enable Receive Billing Alerts in the Billing Preferences page for the CloudWatch metrics to be populated by AWS Billing:

    https://console.aws.amazon.com/billing/home?#/preferences

See the created alarm here:

    https://console.aws.amazon.com/cloudwatch/home?region=us-east-1

(notice the region must be us-east-1 as per description above)

See Also:

    aws_budget_alarm.sh - newer method of doing this using AWS Budgets


$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<threshold_amount_in_USD> [<email_address>]"

help_usage "$@"

threshold="${1:-0.00}"
email="${2:-$(git config user.email || :)}"

# XXX: region has to be us-east-1 because this is where the billing metric data accumulates regardless of which region you actually use
region="us-east-1"

sns_topic="AWS_Charges"

if ! [[ "$threshold" =~ ^[[:digit:]]{1,4}(\.[[:digit:]]{1,2})?$ ]]; then
    usage "invalid threshold argument given - must be 0.01 - 9999.99 USD"
fi

if is_blank "$email"; then
    usage "email address not specified and could not determine email from git config"
fi

timestamp "Creating SNS topic to email '$email' in region '$region'"
output="$(aws sns create-topic --name "$sns_topic" --region "$region" --output json)"

# "arn:aws:sns:us-east-1:123456789012:AWS_Charges"
sns_topic_arn="$(jq -r '.TopicArn' <<< "$output")"

echo

timestamp "Subscribing email address '$email' to topic '$sns_topic' in region '$region'"
aws sns subscribe --topic-arn "$sns_topic_arn" --protocol email --notification-endpoint "$email" --region "$region"

echo

timestamp "Creating CloudWatch Alarm for AWS charges > $threshold USD in region '$region'"
# --period 21600 = 6 hours (default)
aws cloudwatch put-metric-alarm --alarm-name "AWS Charges" \
                                --alarm-description "Alerts on AWS charges greater than $threshold USD" \
                                --actions-enabled \
                                --alarm-actions "$sns_topic_arn" \
                                --region "$region" \
                                --namespace "AWS/Billing" \
                                --metric-name "EstimatedCharges" \
                                --dimensions "Name=Currency,Value=USD" \
                                --threshold "$threshold" \
                                --comparison-operator "GreaterThanThreshold" \
                                --statistic Maximum \
                                --period 21600 \
                                --evaluation-periods 1
