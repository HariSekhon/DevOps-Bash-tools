#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-03-16 19:16:41 +0000 (Wed, 16 Mar 2022)
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
Sends a message to a given SQS queue, fetches it and deletes it

Queue URL argument can be copied from SQS queue page and should look similar to:

    https://sqs.<region>.amazonaws.com/<account_number>/myname.fifo

    eg.

    https://sqs.\$AWS_DEFAULT_REGION.amazonaws.com/\$AWS_ACCOUNT_ID/myname.fifo


$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<queue_url>"

help_usage "$@"

min_args 1 "$@"

queue_url="$1"

epoch="$(date '+%s')"
message_group_id="${0##*/}"
message_deduplication_id="${0##*/}_$epoch"
message_body="message body from script ${0##*/} pid $$ epoch $epoch"

timestamp "sending SQS test message to queue '$queue_url'"
aws sqs send-message --queue-url "$queue_url" --message-body "$message_body" --message-group-id "$message_group_id" --message-deduplication-id "$message_deduplication_id"
echo >&2

sleep 1

timestamp "receiving SQS messages from queue '$queue_url'"
message_json="$(aws sqs receive-message --queue-url "$queue_url" --max-number-of-messages=10)"
echo >&2

timestamp "parsing messages for receipt handle"
receipt_handle="$(jq -r ".Messages[] | select(.Body == \"$message_body\") | .ReceiptHandle" <<< "$message_json")"
echo >&2

if [ -z "$receipt_handle" ]; then
    die "Message handle not found for message with body '$message_body' in queue '$queue_url'"
fi

timestamp "deleting test message using receipt handle"
aws sqs delete-message --queue-url "$queue_url" --receipt-handle "$receipt_handle"
