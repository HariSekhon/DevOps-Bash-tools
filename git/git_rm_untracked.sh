#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2026-11-04 03:37:56 +0900 (Wed, 04 Nov 2026)
#  Original Date: 2019-10-23 15:28:13 +0100
#  Migrated from .bash.d/git.sh function of the same name
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
Deletes untracked files from the local Git checkout

Used to clean up files but be careful because you could lose untracked code you haven't committed

To make it safer this program requires you to specify the search path and also prompts before deleting the files
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<directories_or_files_or_glob>"

help_usage "$@"

min_args 1 "$@"

# iterate on explicit targets only for safety
# intentionally not including current directory to avoid accidentally wiping out untracked files
# you must specify "git_rm_untracked.sh ." if you really intend this
files_to_remove="$(
    for x in "${@:-}"; do
        git status --porcelain -s --untracked-files=all "$x" |
        # this breaks the correct spacings for Spotify playlist filenames
        #awk '/^\?\?/{$1=""; print}' |
        grep '^??' |
        sed 's/^?? //' |
        while read -r filename; do
            # git status --porcelain double quotes file paths when containing unicode chars which are representated in \xxx format
            # you must set 'git config --global core.quotePath false' for this to work properly
            #
            # this doesn't help because you are still stuck with \xxx chars throughout
            filename="${filename#\"}"
            filename="${filename%\"}"
            #echo rm -fv -- "$filename"
            echo "$filename"
        done
    done || :
)"

if is_blank "$files_to_remove"; then
    echo "No Git untracked files to remove"
    exit 0
else
    echo "Files to remove:"
    echo
    echo "$files_to_remove"
    echo
    read -r -p "Are you sure you want remove these files? (y/N)" answer
    check_yes "$answer"
    echo
    echo "Deleting:"
    echo
    while read -r filename; do
        is_blank "$filename" && continue
        rm -fv -- "$filename"
    done <<< "$files_to_remove"
fi
