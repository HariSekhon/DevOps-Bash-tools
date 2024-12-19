#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-12-19 13:54:16 +0700 (Thu, 19 Dec 2024)
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
Returns the AWS CloudFront ARN of the distribution which serves origins containing a given substring

Useful for quickly finding the CloudFront ARN needed to give permissions to a private S3 bucket exposed via CloudFront


$usage_aws_cli_jq_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<domain_substring>"

help_usage "$@"

min_args 1 "$@"

domain_substring="$1"

json="$(
    aws cloudfront list-distributions \
        --query "DistributionList.Items[*].{ARN:ARN, DomainNames:Origins.Items[*].DomainName}" \
        --output json
)"

if [ "$json" = null ]; then
    echo "No CloudFront distributions found. Have you set the right \$AWS_PROFILE environment variable to the correct account?" >&2
    exit 1
fi

jq -r ".[] | select(.DomainNames | map(ascii_downcase | contains(\"$domain_substring\")) | any) | .ARN" <<< "$json"
