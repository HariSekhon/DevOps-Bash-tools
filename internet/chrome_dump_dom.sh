#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2026-09-23 02:52:42 +0900 (Wed, 23 Sep 2026)
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
Uses Chrome in headless mode to dump the final HTML DOM from Javascript constructed pages to stdout
for automated shell processing, such as piping to urlextract.sh or html_href.sh to extract all
HTTP(S) or generic links respectively

Chrome args can be passed as well as the URL

Uses adjacent script chrome.sh to determine the installed location of Chrome across Linux / Mac installations
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<chrome_options>] <url>"

help_usage "$@"

min_args 1 "$@"

"$srcdir/chrome.sh" --headless --dump-dom "$@"
