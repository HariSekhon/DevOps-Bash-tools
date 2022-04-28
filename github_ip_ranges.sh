#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: actions
#
#  Author: Hari Sekhon
#  Date: 2022-02-25 14:57:23 +0000 (Fri, 25 Feb 2022)
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

ip_services=(
    actions
    api
    dependabot
    git
    hooks
    importer
    pages
    web
)

# shellcheck disable=SC2034,SC2154
usage_description="
Returns all the Atlassian IPs ranges in CIDR form

    https://api.github.com/meta

Can specify one of the following services, otherwise returns all:

$(tr ' ' '\n' <<< "${ip_services[*]}" | sed 's/^/    /')
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[service]"

help_usage "$@"

ip_service="${1:-}"

url="https://api.github.com/meta"

data="$(curl -sSf "$url")"

if [ "$ip_service" ]; then
    jq -r ".${ip_service}[]" <<< "$data"
else
    for service in "${ip_services[@]}"; do
        jq -r ".${service}[]" <<< "$data"
    done
fi |
sort -nu
