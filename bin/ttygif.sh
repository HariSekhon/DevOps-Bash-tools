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
Creates a Gif from running terminal commands using ttyrec and ttygif

and then opens the resulting gif

If on Mac uses your \$BROWSER or Google Chrome since Mac Preview shows the individual gif frames
instead of the running gif

Also resizes the terminal to be a standard 80x25 characters before it begins. Set the environment variable
NO_RESIZE_TERMINAL to any value to avoid this

See also adjacent scripts:

    asciinema.sh

    terminalizer.sh


Requires ttygif to be installed, attempts to install it via your package manager if not found in \$PATH
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<output.gif>]"

help_usage "$@"

max_args 1 "$@"

# tty-2024-11-14_19:49:39.gif displays as tty-2024-11-14_19/49/39.gif in Finder
# so use dot separators instead like native Mac screenshots
gif="${1:-tty-$(date '+%F_%H.%M.%S').gif}"
if ! [[ "$gif" =~ \.gif$ ]]; then
    gif="$gif.gif"
fi

ttyrec_recording_file="/tmp/ttyrec.$$"

if ! type -P ttygif &>/dev/null; then
    "$srcdir/../packages/install_packages.sh" ttygif
fi

if [ -z "${NO_RESIZE_TERMINAL:-}" ]; then
    resize -s 25 80
fi

clear

# Makes the PS1 prompt too long which eats into the screen recording terminal space and makes it wrap
# Instead of this, just move the tty.gif at the end
#if [ -d ~/Desktop/Screenshots ]; then
#    timestamp "Switching to ~/Desktop/Screenshots directory"
#    cd ~/Desktop/Screenshots
#fi

timestamp "Now run your commands"

ttyrec "$ttyrec_recording_file"

#export TTYGIF_DEBUG=1

ttygif "$ttyrec_recording_file" -f  # -f includes the terminal window border instead of leaving it half height cut off

# the default filename created is tty.gif
mv -iv tty.gif "$gif"

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
