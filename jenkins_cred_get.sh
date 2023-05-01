#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: haritest
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
Gets the config for a given Jenkins credentials by its ID from the given credential store and domain

Useful to retrieve the configuration of a credential to update it or create a similar credential

Defaults to the 'system' provider's store and global domain '_'

To obtain the credential ID, use jenkins_cred_list.sh

Tested on Jenkins 2.319 with Credentials plugin 2.5

Uses the adjacent jenkins_api.sh - see there for authentication details
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<id> [<store> <domain> <curl_options>]"

help_usage "$@"

min_args 1 "$@"

id="$1"
store="${2:-system}"
domain="${3:-_}"
for _ in {1..3}; do shift || : ; done

"$srcdir/jenkins_api.sh" "/credentials/store/$store/domain/$domain/credential/$id/config.xml" "$@"
echo
