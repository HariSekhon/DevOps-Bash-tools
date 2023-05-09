#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: bash -c 'echo "check id = {id} and name = {name}"'
#
#  Author: Hari Sekhon
#  Date: 2020-08-24 15:25:27 +0100 (Mon, 24 Aug 2020)
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
Run a command against each Pingdom check

All arguments become the command template

WARNING: do not run any command reading from standard input, otherwise it will consume the check id/names and exit after the first iteration

The command template replaces the following for convenience in each iteration:

{id}   - with the check id   <-- this is the one you want for chaining API queries with pingdom_api.sh
{name} - with the check name

eg.
    ${0##*/} 'echo check id = {id} and name = {name}'

For real usage examples, see:

    pingdom_checks_outages.sh
    pingdom_checks_latency_by_hour.sh
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<command> <args>"

help_usage "$@"

min_args 1 "$@"

"$srcdir/pingdom_api.sh" /checks |
jq -r '.checks[] | [.id, .name] | @tsv' |
while read -r check_id check_name; do
    if [ -z "${NO_HEADING:-}" ]; then
        echo "# ============================================================================ #" >&2
        echo "# $check_id - $check_name" >&2
        echo "# ============================================================================ #" >&2
    fi
    cmd=("$@")
    cmd=("${cmd[@]//\{check_id\}/$check_id}")
    cmd=("${cmd[@]//\{check_name\}/$check_name}")
    cmd=("${cmd[@]//\{id\}/$check_id}")
    cmd=("${cmd[@]//\{name\}/$check_name}")
    # need eval'ing to able to inline quoted script
    # shellcheck disable=SC2294
    eval "${cmd[@]}"
done
