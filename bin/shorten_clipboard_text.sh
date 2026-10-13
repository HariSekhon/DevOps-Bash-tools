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
#  If you're using my code you're welcome to connect with me on LinkedIn
#  and optionally send me feedback to help steer this or other code I publish
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
Shortens the text in clipboard to make social media comments shorter

- Copies text from the clipboard
- Replaces \"and\" with \"&\"
- Removes multiple blank lines between paragraphs (which can result from the copy/paste pipeline otherwise)
- Copies the text clipboard text back to be able to immediately paste

Tested on macOS 14
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

no_more_args "$@"

timestamp "Replacing selected clipboard content - 'and' with '&' and collapse multiple blank lines"
#if is_mac; then
#    pbpaste |
#    gsed -E 's/\band\b/\&/g' |
#    cat -s |
#    pbcopy
#elif is_linux; then
#    xclip -o -selection clipboard |
#    sed -E 's/\band\b/\&/g' |
#    cat -s |
#    xclip -selection clipboard
#else
#    die "Unsupported OS: must be either Linux or Mac"
#fi

# re-use these scripts which detect OS and error out correctly if OS is not supported
"$srcdir/paste_from_clipboard.sh" |
sed -E 's/\band\b/\&/g' |
cat -s |
"$srcdir/copy_to_clipboard.sh"
