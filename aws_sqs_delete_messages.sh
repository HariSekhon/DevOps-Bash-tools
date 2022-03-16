#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-03-16 19:36:19 +0000 (Wed, 16 Mar 2022)
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
srcdir="$(dirname "${BASH_SOURCE[0]}")"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Deletes 1-10 AWS SQS messages from a given queue URL

Defaults to 1 message, max 10 messages
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="queue_url [<num_of_messages>]"

help_usage "$@"

min_args 1 "$@"

queue_url="$1"
num_messages="${2:-1}"

aws sqs receive-message --queue-url "$queue_url" --max-number-of-messages="$num_messages" |
jq -r '.Messages[] | .ReceiptHandle' |
while read -r receipt_handle; do
    timestamp "deleting message"
    aws sqs delete-message --queue-url "$queue_url" --receipt-handle "$receipt_handle"
done
