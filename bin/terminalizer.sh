#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-11-14 19:20:36 +0400 (Thu, 14 Nov 2024)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
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
Creates a Gif from running terminal commands using Terminalizer

and then opens the resulting gif

Terminalizer is highly configurable but extremely slow to generate the gif compared to the adjacent
ttygif.sh or asciinema.sh scripts

If on Mac uses your \$BROWSER or Google Chrome since Mac Preview shows the individual gif frames
instead of the running gif

Also resizes the terminal to be a standard 80x25 characters before it begins. Set the environment variable
NO_RESIZE_TERMINAL to any value to avoid this

The colours are more vibrant in ttygif.sh but it also records the Terminal title, which this doesn't

See also faster adjacent scripts:

    ttygif.sh

    asciinema.sh


Requires terminalizer to be installed, attempts to install it via NPM if not found in \$PATH
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<output.gif>]"

help_usage "$@"

max_args 1 "$@"

# tty-2024-11-14_19:49:39.gif displays as tty-2024-11-14_19/49/39.gif in Finder
# so use dot separators instead like native Mac screenshots
gif="${1:-terminalizer-$(date '+%F_%H.%M.%S').gif}"
if ! [[ "$gif" =~ \.gif$ ]]; then
    gif="$gif.gif"
fi

recording_file="/tmp/terminalizer.$$"

if ! type -P terminalizer &>/dev/null; then
    if ! type -P npm &>dev/null; then
        "$srcdir/../packages/install_packages.sh" terminalizer
    fi
    npm install terminalizer
fi

if [ -z "${NO_RESIZE_TERMINAL:-}" ]; then
    resize -s 25 80
fi

clear

timestamp "Now run your commands"

terminalizer record "$recording_file" --skip-sharing

terminalizer render "$recording_file" -o "$gif"

screenshot_dir=~/Desktop/Screenshots

if [ -d "$screenshot_dir" ]; then
    timestamp "Moving $gif to $screenshot_dir"
    mv -iv "$gif" "$screenshot_dir/"
    gif="$screenshot_dir/$gif"
    echo
fi

timestamp "Gif is now available as: $gif"

if is_mac; then
    open -a "${BROWSER:-Google Chrome}" "$gif"
else
    "$srcdir/imageopen.sh" "$gif"
fi
