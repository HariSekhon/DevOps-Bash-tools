#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-10-06 18:59:32 +0100 (Tue, 06 Oct 2020)
#
#  https://github.com/HariSekhon/bash-tools
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

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# vendor's bash completion and other external sources aren't written defensively enough,
# ignoring error codes from commands and testing undefined variables :'-(
set +euo pipefail
# auto-wraps xargs to gxargs for --no-run-if-empty
# shellcheck disable=SC1090
#. "$srcdir/.bash.d/mac.sh"

# providers browser abstraction for Linux + Mac
# shellcheck disable=SC1090
. "$srcdir/.bash.d/network.sh"
set -euo pipefail

# shellcheck disable=SC2034,SC2154
usage_description="
Opens the first URL found in the given file arguments or standard input

Used by .vimrc to instantly open a URL on the given line in the editor

Very useful for quickly referencing inline documentation links in config files and templates such as those found at https://github.com/HariSekhon/templates
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<files>]"

{
# [] break the regex match, even when escaped \[\]
grep -Eom 1 'https?://[[:alnum:]./?&!$#%@*;+~_=-]+' "$@" ||
    die "No URLs found"
} |
# head -n1 because grep -m 1 can't be trusted and sometimes outputs more matches on subsequent lines
head -n1 |
while read -r url; do
    browser "$url"
done
