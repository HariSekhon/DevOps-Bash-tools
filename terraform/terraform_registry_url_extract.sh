#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-12-05 00:26:53 +0700 (Thu, 05 Dec 2024)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
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
Extracts the Terraform Registry URLs in either tfr:// or https://registry.terraform.io/ format
from a given string, file or standard input

Useful to fast load Terraform Module documentation via editor/IDE hotkeys

See advanced .vimc in this repo

Based on ../bin/urlextract.sh
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<string_or_file_with_url>]"

help_usage "$@"

max_args 1 "$@"

arg="${1:-}"

if [ $# -eq 0 ]; then
    cat
elif [ -f "$arg" ]; then
    cat "$arg"
else
    echo "$arg"
fi |
# [] break the regex match, even when escaped \[\]
grep -Eom 1 \
     -e 'tfr://[[:alnum:]./?&!$#%@*;:+~_=-]+' \
     -e 'https://registry.terraform.io/[[:alnum:]./?&!$#%@*;:+~_=-]*' ||
die "No Terraform Registry URLs found"
