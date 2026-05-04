#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-08-11 15:59:59 +0100
#  Migrated out of .bash.d/functions.sh
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn
#  and optionally send me feedback
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
Opens the Google Chrome browser in a portable way between Linux and Mac for use from other scripts

If no URL is given then it defaults to Google.com

Opens in most recent Chrome window

Useful Switches:

--new-window        Opens in a New Window
--incognito         Incognito mode, useful for testing problems with websites without using the cookies cache

This site is useful to see more Chrome switches:

    https://peter.sh/experiments/chromium-command-line-switches/
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<url> <options>]"

help_usage "$@"

#min_args 1 "$@"

#url="${1:-https://google.com}"
#shift || :

#if is_mac; then
    # don't use open because it requires figuring out what is the URL (or prefixing it with http(s):// )
    # and what are the --args to pass to Chrome
    #open -a 'Google Chrome' -u "$url" --args "$@"
    # just call Chrome directly by path for simpler native chrome arg handling to be uniform across platforms
if is_mac &&
    [ -x "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]; then
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" "$@" &
else
    if ! type -P google-chrome &>/dev/null; then
        die "ERROR: google-chrome not found in \$PATH"
    fi
    google-chrome "$@" &
fi
