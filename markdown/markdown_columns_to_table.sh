#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-02-24 17:45:18 +0700 (Mon, 24 Feb 2025)
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
Converts text columns separated by whitespace to a Markdown table with vertically aligned column pipe chars

Reads from a file or standard input

If you don't want the first line to be used as the table header and instead generate placeholder 'Column N' headers:

  export NO_HEADER_ROW=1

Eg.

    SUBDOMAIN='myproject' domains_subdomains_environments.sh | NO_HEADER_ROW=1 ${0##*/}

OR with a manual input (I've spaced them just for clarity here,
   the script will align columns even if the spacing is different regardless)

    ${0##*/} <<< EOF
        Dev             Staging             Production
        dev.domain.com  staging.domain.com  prod.domain.com
        dev.domain2.com staging.domain2.com prod.domain2.com
        dev.domain3.com staging.domain3.com prod.domain3.com
    EOF
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<file>]"

help_usage "$@"

max_args 1 "$@"

if [ $# -eq 1 ]; then
    if ! [ -f "$1" ]; then
        die "File not found: $1"
    fi
    log "${0##*/} Reading from file: $1"
    filename_or_stdin="$1"
elif [ $# -eq 0 ]; then
    log "${0##*/} Reading from stdin"
    filename_or_stdin="-"
else
    usage "More than one arg given"
fi

# do not want string interpolation messing with awk variables
# shellcheck disable=SC2016
awk_script='
BEGIN {
    max_cols = 0
    use_first_row_as_header = (ENVIRON["NO_HEADER_ROW"] == "" || ENVIRON["NO_HEADER_ROW"] == "0")
}

NR == 1 {
    for (i = 1; i <= NF; i++) {
        len = length($i)
        if (use_first_row_as_header) {
            header_name[i] = $i
            max_width[i] = len
        } else {
            if (len > max_width[i]) {
                max_width[i] = len
            }
            data[NR][i] = $i
        }
        if (NF > max_cols) max_cols = NF
    }
}

NR > 1 || (NR == 1 && !use_first_row_as_header) {
    for (i = 1; i <= NF; i++) {
        len = length($i)
        if (len > max_width[i]) {
            max_width[i] = len
        }
        data[NR][i] = $i
    }
    if (NF > max_cols) max_cols = NF
}

END {
    header = "|"
    separator = "|"
    for (i = 1; i <= max_cols; i++) {
        if (use_first_row_as_header) {
            header_name[i] = (i in header_name) ? header_name[i] : sprintf("Column %d", i)
        } else {
            header_name[i] = sprintf("Column %d", i)
        }
        if (length(header_name[i]) > max_width[i]) {
            max_width[i] = length(header_name[i])
        }
        header = header sprintf(" %-" max_width[i] "s |", header_name[i])
        separator = separator sprintf(" %s |", sprintf("%*s", max_width[i], sprintf("%*s", max_width[i], "")))
    }
    gsub(/ /, "-", separator)
    print header
    print separator

    for (row = (use_first_row_as_header ? 2 : 1); row <= NR; row++) {
        line = "|"
        for (col = 1; col <= max_cols; col++) {
            value = (col in data[row]) ? data[row][col] : ""
            line = line sprintf(" %-" max_width[col] "s |", value)
        }
        print line
    }
}
'

awk "$awk_script" "$filename_or_stdin"
