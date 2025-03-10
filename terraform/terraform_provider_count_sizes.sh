#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-03-11 03:28:53 +0800 (Tue, 11 Mar 2025)
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
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Finds duplicate Terraform providers and their sizes

Useful to find space wastage caused by using Terragrunt without configuring a unified Terraform Plugin Cache:

    https://developer.hashicorp.com/terraform/cli/config/config-file#provider-plugin-cache

    https://terragrunt.gruntwork.io/docs/features/provider-cache-server/

    https://github.com/gruntwork-io/terragrunt/issues/561

    https://github.com/gruntwork-io/terragrunt/issues/2920

For example, in a repo checkout for a single project, I had 30 x 600MB AWS provider

    30  597M  hashicorp/aws/5.80.0/darwin_arm64/terraform-provider-aws_v5.80.0_x5
    7   637M  hashicorp/aws/5.90.1/darwin_arm64/terraform-provider-aws_v5.90.1_x5
    4   637M  hashicorp/aws/5.90.0/darwin_arm64/terraform-provider-aws_v5.90.0_x5
    3   599M  hashicorp/aws/5.81.0/darwin_arm64/terraform-provider-aws_v5.81.0_x5
    2   593M  hashicorp/aws/5.79.0/darwin_arm64/terraform-provider-aws_v5.79.0_x5

Output format:

    <count>    <provider_size>    <provider>
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<dir>]"

help_usage "$@"

#min_args 1 "$@"

dir="${1:-.}"

#timestamp "Finding Terraform providers"
# slow way of finding duplicates
#providers="$(find "$dir" -type f -name 'terraform-provider-*' -exec md5sum {} \;)"
providers="$(find "$dir" -type f -name 'terraform-provider-*')"
#echo

if [ -z "$providers" ]; then
    die "ERROR: no Terraform providers found. Did you run this from a Terraform / Terragrunt working directory that has been used?"
fi

#timestamp "Ranking providers by duplication level"
#echo

strip_prefix(){
    sed '
        s|.*\.terraform/providers/||;
        s|registry.terraform.io/||;
    '
}

strip_prefix <<< "$providers" |
sort |
uniq -c |
sort -k1nr |
while read -r count filepath; do
    echo -n "$count "
    # head -n 1 is more reliable than grep -m 1 on some platforms (macOS BSD)
    filename="$(grep "$filepath" <<< "$providers" | head -n 1)"
    du -h "$filename" |
    awk '{printf $1" "}'
    strip_prefix <<< "$filename"
done |
column -t
