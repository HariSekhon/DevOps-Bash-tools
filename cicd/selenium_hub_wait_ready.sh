#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-05-16 10:15:00 +0100 (Sun, 16 May 2021)
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
Waits for Selenium Grid Hub status to be ready

If Selenium hub url isn't given, can construct it from

    \$SELENIUM_HUB_URL
        or
    http://\$SELENIUM_HUB_HOST:\$SELENIUM_HUB_PORT

If \$SELENIUM_HUB_SSL is set, or \$SELENIUM_HUB_PORT is 443, will enable https

Max secs may use environment variable \$MAX_SECS, or defaults to 300
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<selenium_grid_hub_url> [<max_secs>]"

help_usage "$@"

#min_args 1 "$@"

if [ $# -gt 0 ]; then
    hub_url="$1"
else
    if [ -n "${SELENIUM_HUB_URL:-}" ]; then
        hub_url="$SELENIUM_HUB_URL"
    elif [ -n "${SELENIUM_HUB_HOST:-}" ]; then
        hub_url="http://$SELENIUM_HUB_HOST:${SELENIUM_HUB_PORT:-4444}"
        if [ -n "${SELENIUM_HUB_SSL:-}" ] ||
           [ "${SELENIUM_HUB_PORT:-}" = 443 ]; then
            hub_url="https://${hub_url#http://}"
        fi
    else
        usage "selenium hub url not given and \$SELENIUM_HUB_URL / \$SELENIUM_HUB_HOST not set"
    fi
fi
max_secs="${2:-${MAX_SECS:-300}}"

hub_url="${hub_url%%/}"
hub_url="${hub_url%/wd/hub}"

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
