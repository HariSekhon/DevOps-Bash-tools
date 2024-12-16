#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-08-02 15:57:07 +0100 (Mon, 02 Aug 2021)
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
Creates an AWS Budget with an alarm if forecasted to go over 80% of total monthly budget, and another alarm if over 90% of monthly budget

Creates an SNS topic and subscription for the given email address and links it to the above AWS Budgets Alarm to email you as soon as your billing charges are anticipated to go over the threshold. It also modifies the SNS topic's access policy to be accessible from the AWS Budgets service.


The first argument sets the total monthly budget in USD - the 80% and 90% threshold alarms are based on that
The default budget is 0.01 USD (will trigger a notification on any expenditure)

The second argument sets the email address to use in an SNS topic to notify you.
If no email is given specified attempts to use the email from your local Git configuration.
If neither is available, shows this usage mesage.


See the created AWS Budget here (Global):

    https://console.aws.amazon.com/billing/home#/budgets/overview


$usage_aws_cli_jq_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<budget_amount_in_USD> [<email_address>]"

help_usage "$@"

budget="${1:-0.01}"
email="${2:-$(git config user.email || :)}"

region="us-east-1"

sns_topic="AWS_Charges"

if ! [[ "$budget" =~ ^[[:digit:]]{1,4}(\.[[:digit:]]{1,2})?$ ]]; then
    usage "invalid budget argument given - must be 0.01 - 9999.99 USD"
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

timestamp "Getting account id"
account_id="$(aws sts get-caller-identity --query Account --output text)"

echo

# https://docs.aws.amazon.com/cli/latest/reference/sns/set-topic-attributes.html
timestamp "Updating access policy on SNS topic '$sns_topic' to allow AWS Budgets to use it"
aws sns set-topic-attributes --topic-arn "$sns_topic_arn" --attribute-name Policy --attribute-value "$(sed "s/<AWS_SNS_ARN>/$sns_topic_arn/; s/<AWS_ACCOUNT_ID>/$account_id/" "$srcdir/aws_budget_sns_access_policy.json")" --region "$region"

echo

# https://awscli.amazonaws.com/v2/documentation/api/latest/reference/budgets/create-budget.html

timestamp "Checking for existing AWS Budgets"
budgets="$(aws budgets describe-budgets --account-id "$account_id" --query 'Budgets[*].BudgetName' --output text)"

echo

budget_name="$(jq -r .BudgetName < "$srcdir/aws_budget.json")"
if grep -Fxq "$budget_name" <<< "$budgets"; then
    if [ -n "${REPLACE_BUDGET:-}" ]; then
        timestamp "deleting budget '$budget' to replace it"
        aws budgets delete-budget --account-id "$account_id" --budget-name "$budget_name"
        echo
    else
        echo "AWS Budget '$budget' already exists - you must delete it before running this"
        exit 0
    fi
fi

timestamp "Creating AWS Budget with $budget USD budget and 80% forecasted threshold alarm"
aws budgets create-budget --account-id "$account_id" --budget "$(sed "s/<AWS_BUDGET_AMOUNT>/$budget/" "$srcdir/aws_budget.json")" --notifications-with-subscribers "$(sed "s/<AWS_SNS_ARN>/$sns_topic_arn/" "$srcdir/aws_budget_notification.json")"
