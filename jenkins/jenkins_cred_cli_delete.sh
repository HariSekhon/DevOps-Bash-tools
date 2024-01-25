#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: hari-test-cli-user-pass
#
#  Author: Hari Sekhon
#  Date: 2022-06-28 18:34:34 +0100 (Tue, 28 Jun 2022)
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
Deletes a Jenkins Credential in the given credential store and domain

Defaults to the 'system::system::jenkins' provider store and global domain '_'

Tested on Jenkins 2.319 with Credentials plugin 2.5

Uses the adjacent jenkins_cli.sh - see there for authentication details
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<credential_id> [<store> <domain>]"

help_usage "$@"

min_args 1 "$@"

id="${1:-}"
store="${2:-${JENKINS_SECRET_STORE:-system::system::jenkins}}"
domain="${3:-${JENKINS_SECRET_DOMAIN:-_}}"

domain_name="$domain"
if [ "$domain_name" = '_' ]; then
    domain_name='GLOBAL'
fi

timestamp "Deleting Jenkins credential '$id' in store '$store' domain '$domain_name'"
"$srcdir/jenkins_cli.sh" delete-credentials "$store" "$domain" "$id"
timestamp "Secret '$id' deleted"
