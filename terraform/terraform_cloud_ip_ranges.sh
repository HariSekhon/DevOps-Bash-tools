#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-12-20 13:32:36 +0000 (Mon, 20 Dec 2021)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://www.terraform.io/cloud-docs/api-docs/ip-ranges

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Returns the list of IP ranges that Terraform Cloud may use via the API

Can optionally return just the IP lists for one or more of the following range types:

    api
    notifications
    sentinel
    vcs

For more details, see:

    https://www.terraform.io/cloud-docs/api-docs/ip-ranges
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<range_type> <range_type> ...]"

help_usage "$@"

#min_args 1 "$@"

for range_type in "$@"; do
    if ! [[ "$range_type" =~ ^(api|notifications|sentinel|vcs)$ ]]; then
        usage "invalid range type given, must be one of: api, notifications, sentinel, vcs"
    fi
done

data="$(curl -sS https://app.terraform.io/api/meta/ip-ranges)"

if [ -n "${DEBUG:-}" ]; then
    jq . <<< "$data" >&2
fi

if [ $# -gt 0 ]; then
    for range_type in "$@"; do
        jq -r ".${range_type}[]" <<< "$data"
    done
else
    jq -r '.[][]' <<< "$data"
fi |
sort -u
