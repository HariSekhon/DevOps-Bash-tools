#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-08-11 15:59:59 +0100
#  Migrated out of .bash.d/network.sh
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


# time between opening multiple tabs from stdin
sleep_interval="0.3"

default_url="https://google.com"

# shellcheck disable=SC2034,SC2154
usage_description="
Opens URL(s) in the Firefox browser in a portable way between Linux and Mac for use from other scripts

URLs must be prefixed by http:// or https:// otherwise they are ignore and firefox just opens a blank tab

If no URL is given defaults to $default_url

To read multiple URLs from stdin, use a dash as an arg.
Adds a delay of $sleep_interval secs between opening each one in order to not DoS or get rate limited by a website

Opens in most recent Firefox window

Useful Switches:

--new-window        Opens in a New Window
--devtools          Opens with Dev Tools running
--private-window    Private mode, useful for testing problems with websites without using the cookies cache

Another thing you can do on Mac is to add /Applications/Firefox.app/Contents/MacOS/ to your \$PATH and
just call the firefox command as its the same on both platforms unlike with Chrome
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<options> <urls>]"

help_usage "$@"

firefox(){
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
        command firefox "$@" &
    fi
}

firefox_stdin(){
    warn "Reading URLs from stdin"
    lines=0
    while read -r line; do
        is_blank "$line" && continue
        timestamp "Opening Firefox with args + stdin URL: $* $line"
        firefox "$@" "$line"
        lines="$((lines + 1))"
        timestamp "Sleeping for $sleep_interval secs"
        sleep "$sleep_interval"
    done
    if [ "$lines" -eq 0 ]; then
        timestamp "No URLs passed to std, opening Firefox to default URL: $default_url"
        firefox "$@" "$default_url"
    fi
}

if [ $# -eq 0 ]; then
    timestamp "Opening Firefox to default URL: $default_url"
    firefox "$default_url"
else
    stdin=0
    args=()
    for arg; do
        if [ "$arg" = "-" ]; then
            stdin=1
        else
            args+=("$arg")
        fi
    done

    if [ "$stdin" = 1 ]; then
        firefox_stdin "${args[@]}"
    else
        timestamp "Opening Firefox with args: $*"
        firefox "$@"
    fi
fi
