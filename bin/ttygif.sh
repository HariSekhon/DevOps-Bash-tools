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

(if on Mac uses your browser since Mac Preview shows the gif frames instead of the running gif)
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

num_args 0 "$@"

ttyrec_recording_file="/tmp/ttyrec.$$"

resize -s 25 80

clear

# Makes the PS1 prompt too long which eats into the screen recording terminal space and makes it wrap
# Instead of this, just move the tty.gif at the end
#if [ -d ~/Desktop/Screenshots ]; then
#    timestamp "Switching to ~/Desktop/Screenshots directory"
#    cd ~/Desktop/Screenshots
#fi

timestamp "Now run your commands"

ttyrec "$ttyrec_recording_file"

ttygif "$ttyrec_recording_file"

# the default filename created is tty.gif
gif="tty.gif"

screenshot_dir=~/Desktop/Screenshots

if [ -d "$screenshot_dir" ]; then
    # tty-2024-11-14_19:49:39.gif displays as tty-2024-11-14_19/49/39.gif in Finder
    # so use dot separators instead like native Mac screenshots
    new_file="$screenshot_dir/tty-$(date '+%F_%H.%M.%S').gif"
    timestamp "Moving $gif to $new_file"
    mv -iv "$gif" "$new_file"
    gif="$new_file"
fi

timestamp "Gif is now available as $gif"

if is_mac; then
    open -a "${BROWSER:-Google Chrome}" "$gif"
else
    "$srcdir/imageopen.sh" "$gif"
fi
