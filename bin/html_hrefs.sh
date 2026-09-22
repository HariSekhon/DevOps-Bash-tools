#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2026-09-23 02:33:37 +0900 (Wed, 23 Sep 2026)
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
Parses href links out of an HTML page given as a file or read from standard input

Uses xmllint for correct parsing and ignores parsing errors as many HTML pages have imperfections

This is a very general solution and will collect all types of links, so you might want to:

    grep -i 'https*://'

Attempts to install xmllint using whatever package manager is available if it not found in \$PATH

For a simpler pure shell HTTP(S) URL extractor, see also:

    urlextract.sh
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<html_file>]"

help_usage "$@"

max_args 1 "$@"

if ! type -P xmllint &>/dev/null; then
    "$srcdir/../packages/install_packages_if_absent.sh" xmllint
fi

# ignore stderr, noisy imperfections in HTML parsing do not induce non-zero exit code
xmllint --html --xpath '//a/@href' "${@:-}" 2>/dev/null |

# strip leading href=" and trailing "
sed '
    s/^[[:space:]]*href=["'\'']//;
    s/[[:space:]]*["'\''][[:space:]]*$//
'
