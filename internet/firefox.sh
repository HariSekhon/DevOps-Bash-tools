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
Opens a URL in the Firefox browser in a portable way between Linux and Mac for use from other scripts

If no URL is given then it defaults to Google.com

Opens in most recent Firefox window

Useful Switches:

--new-window        Opens in a New Window
--devtools          Opens with Dev Tools running
--private-window    Private mode, useful for testing problems with websites without using the cookies cache

Another thing you can do on Mac is to add /Applications/Firefox.app/Contents/MacOS/ to your \$PATH and
just call the firefox command as its the same on both platforms unlike with Chrome

This script maintains parity with the adjacent chrome.sh script
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
    # and what are the --args to pass to Firefox
    #open -a 'Firefox' -u "$url" --args "$@"
    # just call Firefox directly by path for simpler native firefox arg handling to be uniform across platforms
if is_mac &&
    [ -x "/Applications/Firefox.app/Contents/MacOS/firefox" ]; then
    "/Applications/Firefox.app/Contents/MacOS/firefox" "$@" &
else
    if ! type -P firefox &>/dev/null; then
        die "ERROR: firefox not found in \$PATH"
    fi
    firefox "$@" &
fi
