#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-09-20 16:24:51 +0100 (Tue, 20 Sep 2022)
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
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Parses Terraform Plan for aws_ssoadmin_account_assignment additions and imports each one into Terraform state

If \$TERRAFORM_PRINT_ONLY is set to any value, prints the commands to stdout to collect so you can check, collect into a text file or pipe to a shell or further manipulate, ignore errors etc.


Requires Terraform to be installed and configured
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<dir>]"

help_usage "$@"

dir="${1:-.}"

cd "$dir"

# don't do this because would have to parse references, and then double parse to find the values of the object references :-/
#terraform show -json plan.zip

terraform plan -no-color |
sed -n '/# aws_ssoadmin_managed_policy_attachment\..* will be created/,/}/ p' |
awk '/# aws_ssoadmin_managed_policy_attachment/ {print $2};
     /instance_arn|managed_policy_arn|permission_set_arn/ {print $4}' |
sed 's/^"//; s/"$//' |
xargs -n4 echo |
sed 's/\[/["/; s/\]/"]/' |
while read -r name instance_arn managed_policy_arn permission_set_arn; do
    [ -n "$permission_set_arn" ] || continue
    timestamp "Importing $name"
    cmd=(terraform import "$name" "$managed_policy_arn,$permission_set_arn,$instance_arn")
    timestamp "${cmd[*]}"
    if [ -z "${TERRAFORM_PRINT_ONLY:-}" ]; then
        "${cmd[@]}"
    fi
    echo >&2
done
