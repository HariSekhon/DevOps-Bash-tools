#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-01-21 18:32:36 +0000 (Tue, 21 Jan 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Lists KMS keys and whether they have key rotation enabled
#
# Output Format:
#
# KMS_Key       Rotation_Enabled (boolean)

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

aws kms list-keys |
jq -r '.Keys[].KeyId' |
while read -r key; do
    printf "%s\t" "$key"
    aws kms get-key-rotation-status --key-id "$key" |
    jq -r '.KeyRotationEnabled' || :  # continue leaving blank if no permissions on a given key
done
