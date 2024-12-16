#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-12-17 02:39:54 +0700 (Tue, 17 Dec 2024)
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
Authenticates Docker to AWS ECR, inferring the ECR registry from the current AWS Account ID and Region

If \$AWS_ACCOUNT_ID and \$AWS_DEFAULT_REGION are not set in the environment,
tries to infer them from the current AWS config


$usage_aws_cli_required, and also Docker must be installed
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<ecr_registry>]"

help_usage "$@"

max_args 1 "$@"

export AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-$(aws_account_id)}"

export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-$(aws_region)}"

aws_ecr_registry="${1:-$(aws_ecr_registry)}"

if ! is_aws_ecr_registry "$aws_ecr_registry"; then
    die "Invalid AWS ECR registry: $aws_ecr_registry"
fi

timestamp "Getting AWS ECR Login password and piping it into Docker for registry: $aws_ecr_registry"
aws ecr get-login-password |
docker login --username AWS --password-stdin "$aws_ecr_registry"
