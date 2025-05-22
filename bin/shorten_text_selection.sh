#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-05-19 01:44:50 +0300 (Mon, 19 May 2025)
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
Shortens the selected text in the prior window

- Replaces \"and\" with \"&\"
- Removes multiple blank lines between paragraphs (which result from the pbpaste/pbcopy pipeline otherwise)

I use this a lot for LinkedIn comments due to the short 1250 character limit
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

no_more_args "$@"

if is_mac; then
    exec "$srcdir/../applescript/shorten_text_selection.scpt"
fi

for bin in xdotool xclip; do
    if ! type -P "$bin"; then
        timestamp "Command '$bin' not found in \$PATH, attempting to install..."
        "$srcdir/../packages/install_packages.sh" "$bin"
    fi
done

check_bin xdotool
check_bin xclip

timestamp "Switching back to previous application"
xdotool keydown alt
xdotool key Tab
xdotool keyup alt
sleep 0.3
echo

timestamp "Copying selected content (Ctrl-C)"
xdotool key ctrl+c
sleep 0.1
echo

timestamp "Replacing selected clipboard content - 'and' with '&' and collapse multiple blank lines"
xclip -o -selection clipboard |
sed -E 's/\band\b/\&/g' |
cat -s |
xclip -selection clipboard
sleep 0.1
echo

timestamp "Pasting modified clipboard content back to app (Ctrl-v)"
xdotool key ctrl+v
