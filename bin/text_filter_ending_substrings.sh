#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2026-01-03 03:15:56 -0500 (Sat, 03 Jan 2026)
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
For a given patterns file of substring endings, print all lines that match in the following files

Uses awk to safely handle all characters as literals, unlike grep, while also maintaining end anchoring
which you cannot do using grep -F.

Optimized awk code uses a bucketing hash for performance to not attempt matching lines which are shorter
than patterns, reducing the number of match attempts

By default matching is case sensitive for accuracy, but if you want case insensitive matching, you can set
environment variable TEXT_MATCH_CASE_INSENSITIVE to 1

    export TEXT_MATCH_CASE_INSENSITIVE=1

You can also pass subshell content outputs for one of both 'files' using bash file descriptor replacement syntax:

    ${0##*/} <(somecommand) <(somecommand2)

Used by script:

    $srcdir/../spotify/spotify_delete_from_playlist_if_track_in_other_playlists.sh
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<patterns.txt> <data.txt> [<data2.txt> ...]"

help_usage "$@"

min_args 2 "$@"

for arg; do
    if ! [ -e "$arg" ]; then
        die "ERROR: not found: $arg"
    fi
done

patterns_file="$1"
shift || :

awk '
    BEGIN {
        ci = (ENVIRON["TEXT_MATCH_CASE_INSENSITIVE"] == "1")
    }

    # block only executes for 1st file to build up the patterns hash
    NR==FNR {
        pattern = ci ? tolower($0) : $0
        len = length(pattern)
        # length bucketing optimization to not attempt to match lines that are shorter than length
        patterns[len][pattern] = 1
        #if (len > max) max = len
        next
    }
    {
        line = ci ? tolower($0) : $0
        len_line = length(line)
        for (pattern in patterns) {
            if (len_line >= pattern) {
                suffix = substr(line, len_line - pattern + 1)
                if (suffix in patterns[pattern]) {
                    print
                    break
                }
            }
        }
    }
' "$patterns_file" "$@"
