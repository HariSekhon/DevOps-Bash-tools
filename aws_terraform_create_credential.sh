#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-02-20 17:26:21 +0000 (Sat, 20 Feb 2021)
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
Creates an AWS terraform service account for Terraform Cloud or other CI/CD systems to run terraform plan and apply

Grants this service account Administator privileges in the current AWS account unless a different group or policy is specified as a second argument

Creates an IAM access key (deleting an older unused key if necessary), writes a CSV just as the UI download would, and outputs both shell export commands and configuration in the format for copying to your AWS profile in ~/.aws/credentials

The following optional arguments can be given:

- user name         (default: \$USER-terraform)
- group or policy   (default: Admins group if found, else AdministratorAccess standard AWS-managed policy)
- keyfile           (default: ~/.aws/keys/\${user}_\${aws_account_id}_accessKeys.csv) - be careful if specifying this, a non-existent keyfile will create a new key, deleting the older of 2 existing keys if necessary to be able to create this

Idempotent - safe to re-run, will skip creating a user that already exists or CSV export that already exists

Examples:

    # creates user 'github-actions-MYREPO' with full AdministratorAccess and saves the key in ~/.aws/keys/

        ${0##*/} github-actions-MYREPO

    # creates a read-only user 'github-actions-MYREPO-readonly' with ReadOnlyAccess standard AWS-managed policy attached for GitHub Actions environment secret that can be automatically used in Pull Request workflows without approval, saves key to ~/.aws/keys/

        ${0##*/} github-actions-MYREPO-readonly ReadOnlyAccess


$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<username> <group_or_policy> <keyfile>]"

help_usage "$@"

#min_args 1 "$@"

user="${1:-$USER-terraform}"
shift || :

# done as part of aws_cli_create_credential.sh now
#aws_account_id="$(aws sts get-caller-identity --query Account --output text)"

"$srcdir/aws_cli_create_credential.sh" "$user" "$@"  #  AdministratorAccess  "$HOME/.aws/keys/${user}_${aws_account_id}_accessKeys.csv" # default location now
