#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: echo zone id = {id} and name = {name}
#
#  Author: Hari Sekhon
#  Date: 2020-09-02 18:08:43 +0100 (Wed, 02 Sep 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
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
Run a command against each Cloudflare zone

All arguments become the command template

WARNING: do not run any command reading from standard input, otherwise it will consume the zone id/names and exit after the first iteration

The command template replaces the following for convenience in each iteration:

{id}   - with the zone id   <-- this is the one you want for chaining API queries with cloudflare_api.sh
{name} - with the zone name

eg.
    ${0##*/} 'echo zone id = {id} and name = {name}'
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<command> <args>"

help_usage "$@"

min_args 1 "$@"

"$srcdir/cloudflare_api.sh" zones |
jq -r '.result[] | [.id, .name] | @tsv' |
sed "s/'/\\\\'/g" |
while read -r zone_id zone_name; do
    if [ -z "${NO_HEADING:-}" ]; then
        echo "# ============================================================================ #" >&2
        echo "# $zone_id - $zone_name" >&2
        echo "# ============================================================================ #" >&2
    fi
    cmd=("$@")
    cmd=("${cmd[@]//\{zone_id\}/$zone_id}")
    cmd=("${cmd[@]//\{zone_name\}/$zone_name}")
    cmd=("${cmd[@]//\{id\}/$zone_id}")
    cmd=("${cmd[@]//\{name\}/$zone_name}")
    # need eval'ing to able to inline quoted script
    # shellcheck disable=SC2294
    eval "${cmd[@]}"
done
