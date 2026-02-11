#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2026-02-11 01:05:32 -0300 (Wed, 11 Feb 2026)
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
Dumps the GNU Screen terminal output to a temp file and
copies to clipboard for sharing & debugging purposes

You can pass screen options as args such as:

    -S session_name
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<screen_options>]"

help_usage "$@"

# indicate to screen_terminal_to_stdout.sh not to remove the term
export SCREEN_TERMINAL_NO_DELETE_TEMPFILE=1

"$srcdir/screen_terminal_to_stdout.sh" "$@" |
"$srcdir/copy_to_clipboard.sh"

timestamp "Copied GNU Screen to Clipboard"
