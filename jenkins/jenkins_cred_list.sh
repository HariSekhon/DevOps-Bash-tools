#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
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
Lists Jenkins Credentials in the given credential store and domain

Defaults to the 'system' provider's store and global domain '_'

Tested on Jenkins 2.319 with Credentials plugin 2.5

Uses the adjacent jenkins_api.sh - see there for authentication details


The returned credential IDs are what you should be specifying in your Jenkinsfile pipeline:

    environment {
        MYVAR = credentials('some-id')
    }

See master Jenkinsfile for more examples:

    https://github.com/HariSekhon/Jenkins/blob/master/Jenkinsfile
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<store> <domain> <curl_options>]"

help_usage "$@"

store="${1:-system}"
domain="${2:-_}"
shift || :
shift || :

"$srcdir/jenkins_api.sh" "/credentials/store/$store/domain/$domain/api/json?tree=credentials\\[id\\]" "$@" |
jq -r '.credentials[].id' |
sort -f
