#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: echo account id = {id} and name = "{name}"
#
#  Author: Hari Sekhon
#  Date: 2020-09-02 18:08:43 +0100 (Wed, 02 Sep 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "$0")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Run a command against each Cloudflare account

All arguments become the command template

The command template replaces the following for convenience in each iteration:

{id}   - with the account id   <-- this is the one you want for chaining API queries with cloudflare_api.sh
{name} - with the account name

eg.
    ${0##*/} 'echo account id = {id} and name = {name}'
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<command> <args>"

help_usage "$@"

min_args 1 "$@"

cmd_template="$*"

while read -r account_id account_name; do
    if [ -z "${NO_HEADING:-}" ]; then
        echo "# ============================================================================ #" >&2
        echo "# $account_id - $account_name" >&2
        echo "# ============================================================================ #" >&2
    fi
    cmd="$cmd_template"
    cmd="${cmd//\{account_id\}/$account_id}"
    cmd="${cmd//\{account_name\}/$account_name}"
    cmd="${cmd//\{id\}/$account_id}"
    cmd="${cmd//\{name\}/$account_name}"
    eval "$cmd"
done < <("$srcdir/cloudflare_api.sh" accounts | jq -r '.result[] | [.id, .name] | @tsv' | sed "s/'/\\\\'/g")
