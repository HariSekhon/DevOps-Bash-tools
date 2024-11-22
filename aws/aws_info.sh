#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  shellcheck disable=SC1091
#
#  Author: Hari Sekhon
#  Date: 2024-11-22 14:20:14 +0400 (Fri, 22 Nov 2024)
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
Lists AWS deployed resources in the current or specified AWS account profile

Written to be combined with aws_foreach_profile.sh


$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<aws_profile>]"

help_usage "$@"

max_args 1 "$@"

check_bin aws

if [ $# -gt 0 ]; then
    aws_profile="$1"
    shift || :
    export AWS_PROFILE="$aws_profile"
fi


cat <<EOF
# ============================================================================ #
#                                 A W S   C L I
# ============================================================================ #

EOF

aws --version
echo
echo

## ============================================================================ #
. "$srcdir/aws_info_ec2.sh"
echo
echo

## ============================================================================ #
#. "$srcdir/gcp_info_auth_config.sh"
#echo
#echo

## ============================================================================ #
#. "$srcdir/gcp_info_projects.sh"
#echo
#echo

## ============================================================================ #
#. "$srcdir/gcp_info_services.sh"
#echo
#echo
#
## ============================================================================ #
#. "$srcdir/gcp_info_accounts_secrets.sh"
#echo
#echo
#
## ============================================================================ #
#. "$srcdir/gcp_info_compute.sh"
#echo
#echo
#
## ============================================================================ #
#. "$srcdir/gcp_info_storage.sh"
#echo
#echo
#
## ============================================================================ #
#. "$srcdir/gcp_info_networking.sh"
#echo
#echo
#
## ============================================================================ #
#. "$srcdir/gcp_info_bigdata.sh"
#echo
#echo
#
## ============================================================================ #
#. "$srcdir/gcp_info_tools.sh"
#echo
#echo

# Finished - silencing aws_account_name because you may not have the permissions to AWS Org to retrieve it
cat <<EOF
# ============================================================================ #
# Finished listing resources for AWS account $(aws_account_id) $(aws_account_name 2>/dev/null)
# ============================================================================ #
EOF
