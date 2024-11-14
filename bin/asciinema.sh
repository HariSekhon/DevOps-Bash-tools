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
Creates a Gif from running terminal commands using asciinema and agg

and then opens the resulting gif

If on Mac uses your \$BROWSER or Google Chrome since Mac Preview shows the individual gif frames
instead of the running gif

Also resizes the terminal to be a standard 80x25 characters before it begins. Set the environment variable
NO_RESIZE_TERMINAL to any value to avoid this

The colours are more vibrant in ttygif.sh but it also records the Terminal title, which this doesn't


Requires asciinema and agg to be installed, attempts to install them via your package manager if not found in \$PATH
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

num_args 0 "$@"

recording_file="/tmp/asciinema.$$"

if ! type -P asciinema &>/dev/null; then
    "$srcdir/../packages/install_packages.sh" asciinema
fi

if ! type -P agg &>/dev/null; then
    "$srcdir/../packages/install_packages.sh" agg
fi

if [ -z "${NO_RESIZE_TERMINAL:-}" ]; then
    resize -s 25 80
fi

clear

timestamp "Now run your commands"

asciinema rec "$recording_file"

# the default filename created is tty.gif
gif="${recording_file%.cast}.gif"

agg "$recording_file" "$gif"

screenshot_dir=~/Desktop/Screenshots

if [ -d "$screenshot_dir" ]; then
    new_file="$screenshot_dir/asciinema-$(date '+%F_%H.%M.%S').gif"
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
