#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-02-25 23:53:53 +0000 (Sun, 25 Feb 2024)
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
Checks if a given Solr collection exists via the Solr API

Uses the adjacent script solr_api.sh - see it for required environment variables and authentication

See Also

    Solr CLI - https://github.com/HariSekhon/DevOps-Perl-tools
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<collection_name> [<curl_options>]"

help_usage "$@"

min_args 1 "$@"

collection="$1"
shift || :

if "$srcdir/solr_api.sh" "/solr/admin/collections?action=LIST" | jq -r '.collections[]' | grep -Fxq "$collection"; then
    timestamp "Solr collection '$collection' exists"
else
    timestamp "Solr collection '$collection' does not exist"
    exit 1
fi
