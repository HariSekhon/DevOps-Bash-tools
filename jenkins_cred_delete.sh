#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: hari-test-api-user-pass
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

# https://github.com/jenkinsci/credentials-plugin/blob/master/docs/user.adoc#creating-a-credentials

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Deletes a Jenkins Credential in the given credential store and domain

Defaults to the 'system' provider's store and global domain '_'

Tested on Jenkins 2.319 with Credentials plugin 2.5

Uses the adjacent jenkins_api.sh - see there for authentication details
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<credential_id> <store> <domain> [<curl_options>]"

help_usage "$@"

id="${1:-}"
store="${2:-${JENKINS_SECRET_STORE:-system}}"
domain="${3:-${JENKINS_SECRET_DOMAIN:-_}}"
for _ in {1..3}; do shift || : ; done
curl_args=("$@")

domain_name="$domain"
if [ "$domain_name" = '_' ]; then
    domain_name='GLOBAL'
fi
timestamp "Deleting Jenkins username/password credential '$id' in store '$store' domain '$domain_name'"
"$srcdir/jenkins_api.sh" "/credentials/store/$store/domain/$domain/credential/$id/config.xml" -X DELETE ${curl_args:+"${curl_args[@]}"}
timestamp "Secret '$id' deleted"
