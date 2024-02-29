#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-02-29 12:46:27 +0000 (Thu, 29 Feb 2024)
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
Deletes duplicate files with (N) suffixes in the given or current directory that are 100% exact duplicate matches by checksum

Checks there is a matching basename file without the (N) suffix with the exact same checksum for safety

Prompts to delete per file. To auto-accept deletions, do

    yes | ${0##*/}

These sorts of duplicates are commonly caused by clicking Download twice in your web browser

I wrote this to run in local crontab to keep my ~/Downloads directory cleaner without wasting my time to clean it up manually

Uses adjacent script find_duplicate_files_by_checksum.sh

Tested on macOS
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<directory>]"

help_usage "$@"

max_args 2 "$@"

cd "${1:-.}"

# read from file descriptor 3 to not slurp stdin which we need for user prompting
while read -r -u 3 checksum filename; do
    if [[ "$filename" =~ \([[:digit:]]\) ]]; then
        log "Checking if we can safetly remove: $filename"
        file_extension="${filename##*.}"
        # false positive - this works fine
        # shellcheck disable=SC2295
        base_filename="${filename% ([[:digit:]]).$file_extension}.$file_extension"
        if [ -f "$base_filename" ]; then
            base_filename_checksum="$(md5sum "$base_filename" | awk '{print $1}')"
            if [ "$base_filename_checksum" = "$checksum" ]; then
                log "Base filename exists and checksum matches, removing: $filename"
                rm -i -v "$filename"
            else
                log "Base filename '$base_filename' checksum '$base_filename_checksum' does not match duplicate file checksum '$checksum', skipping removal for safety"
            fi
        else
            log "No matching basename file found: $base_filename"
            log "Skipping removal for safety"
        fi
        log
    fi
done 3< <( "$srcdir/find_duplicate_files_by_checksum.sh" )
