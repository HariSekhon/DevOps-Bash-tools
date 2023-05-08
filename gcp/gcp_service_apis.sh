#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-26 16:59:50 +0100 (Wed, 26 Aug 2020)
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
List GCP Services, APIs and their states:

Output:

<state>     <api>   <name>

Useful to check whether a service API, used by gcp_info_services.sh

Contains the function is_service_enabled() for sourcing - takes as an argument the API name eg. for GKE specify

    is_service_enabled container.googleapis.com

where container.googleapis.com is the API corresponding to GKE, as you can see in the output from this script
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

# Don't change order of headings here as is_services_enabled() below depends on this

services_list="$(gcloud services list --available --format "table[no-heading](state, config.name, config.title)")"

echo "$services_list"

is_service_enabled(){
    # must be the api path, eg. file.googleapis.com
    local service="$1"
    service="${service//./\.}"  # escape dots for grep
    grep -Eqi "^ENABLED[[:space:]]+$service" <<< "$services_list"
}
