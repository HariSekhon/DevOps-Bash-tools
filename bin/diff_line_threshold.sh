#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-09-21 18:57:40 +0100 (Sat, 21 Sep 2024)
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
Compares two files vs a line count diff threshold to determine if they are radically different

Used to avoid overwriting files which are not mere updates but completely different files

The max_line_diff threshold is 100 is not specified

Used by the following scripts to avoid overwriting configs in adjacent repos:

../cicd/sync_ci_to_adjacent_repos.sh
../cicd/sync_configs_to_adjacent_repos.sh

to avoid overwriting master templates in the Templates repo with CI/CD configs from this repo

If QUIET environment variable is set to any value then doesn't print anything, to not pollute logs for usage in above scripts
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<file1> <file2> [<max_line_diff>]"

help_usage "$@"

min_args 2 "$@"

file1="$1"
file2="$2"

line_threshold="${3:-100}"

if [ -n "${QUIET:-}" ]; then
    timestamp(){
        :
    }
fi

timestamp "Comparing File 1: $file1"
timestamp "Comparing File 2: $file2"
timestamp "Threshold for line difference: $line_threshold"

diff_line_count=$(diff -U 0 "$file1" "$file2" | grep -cE '^[+-]' || :)

timestamp "Total Number of Diff Lines: $diff_line_count"

if [ "$diff_line_count" -ge "$line_threshold" ]; then
    timestamp "Files '$file1' and '$file2' are radically different with $diff_line_count differing lines >= $line_threshold threshold"
    timestamp "Exit: 1"
    exit 1
else
    timestamp "Files '$file1' and '$file2' are not radically different with only $diff_line_count differing lines < $line_threshold threshold"
    timestamp "Exit: 0"
fi
