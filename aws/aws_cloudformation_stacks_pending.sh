#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-12-11 12:22:59 +0000 (Fri, 11 Dec 2020)
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
Lists CloudFormation stacks not marked as completed

Useful with the 'watch' command or in a loop as a latch (hint: use grep) to check until there are no pending CloudFormation stacks before continuing


Arguments are fed to AWS CLI eg. to set --region

Output Format:

<status>    <stack_name>    <stack_description>


$usage_aws_cli_jq_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<aws_cli_options>]"

help_usage "$@"


aws cloudformation list-stacks --output json "$@" |
jq -r '.StackSummaries[] | [.StackStatus, .StackName, .TemplateDescription] | @tsv' |
{ grep -Ev '^([[:alnum:]_]+)?COMPLETE' || : ; }
