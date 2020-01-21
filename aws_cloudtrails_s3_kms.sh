#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-01-21 18:25:39 +0000 (Tue, 21 Jan 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Lists Cloud Trails and whether their S3 buckets are KMS secured
#
# Output Format:
#
# CloudTrail_Name      S3_KMS_secured (boolean)     KMS_Key_Id

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

aws cloudtrail describe-trails |
jq -r '.trailList[] | [.Name, .KmsKeyId] | @tsv' |
while read -r name keyid; do
    kms_secured=false
    if [ -n "$keyid" ]; then
        kms_secured=true
    else
        keyid="N/A"
    fi
    printf "%s\t%s\t%s" "$name" "$kms_secured" "$keyid"
done |
sort |
column -t
