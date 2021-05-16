#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-05-16 10:15:00 +0100 (Sun, 16 May 2021)
#
#  https://github.com/HariSekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "${BASH_SOURCE[0]}")"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Waits for Selenium Grid Hub status to be ready
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<selenium_grid_hub_url> [<max_secs>]"

help_usage "$@"

min_args 1 "$@"

hub_url="$1"
max_secs="${2:-}"

if [ -n "$max_secs" ] &&
   [[ "$max_secs" =~ ^[[:digit:]]+$ ]]; then
	timestamp "setting timeout to $max_secs secs"
	TMOUT="$max_secs"
	# shellcheck disable=SC2064
	trap_cmd "echo 'Timed out waiting for Selenium Grid Hub to come up after $max_secs secs' >&2; exit 1"
fi

while :; do
	status="$(curl -sSL "$hub_url/wd/hub/status")"
	ready="$(jq -r '.value.ready' <<< "$status" || die "FAILED to parse Selenium Hub response: $status" >&2)"
	if [[ "$ready" =~ true ]]; then
		timestamp "Selenium Grid Hub is up"
		break
	fi
    timestamp 'Waiting for Selenium Grid Hub to be ready'
    sleep 1
done

untrap
