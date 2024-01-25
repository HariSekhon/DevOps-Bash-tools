#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-01-16 10:41:43 +0000 (Sun, 16 Jan 2022)
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
Checks for broken symlinks that don't point to existing targets

Traverses the given directory or \$PWD
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<starting_directory>]"

help_usage "$@"

#min_args 1 "$@"

basedir="${1:-.}"

section "Symlink Check"

start_time="$(start_timer)"

failing_symlinks=0
while read -r symlink; do
    if [[ "$symlink" =~ /\.git/ ]]; then
       continue
    fi
    # readlink -f fails to return anything if a parent dir component doesn't exist
    target="$(readlink -m "$symlink" || :)"
    echo -n '.'
    # shouldn't happen now switched from readlink -f to readlink -m
    if [ -z "$target" ]; then
        echo
        echo "WARNING: symlink '$symlink' target could not be resolved" >&2
        ((failing_symlinks+=1))
    elif ! [ -e "$target" ]; then
        echo
        echo "WARNING: symlink '$symlink' => '$target' - target does not exist" >&2
        ((failing_symlinks+=1))
    fi
done < <(find "$basedir" -type l)
echo

if [ "$failing_symlinks" -gt 0 ]; then
    echo
    echo "ERROR: broken symlinks found!" >&2
    echo
    exit 1
fi

time_taken "$start_time"
section2 "All Symlink checks passed"
echo
