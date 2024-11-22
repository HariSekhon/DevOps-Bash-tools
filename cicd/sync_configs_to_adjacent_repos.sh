#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-02-13 15:36:35 +0000 (Thu, 13 Feb 2020)
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
Syncs configs listed in ../setup/files.txt to all adjacent repo checkouts listed in ../setup/repos.txt

Quick way of updating dotfile configs between repos

and then using ../git/github_foreach_repo.sh to commit them
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<files_to_sync>]"

help_usage "$@"

num_args 0 "$@"

cd "$srcdir/.."

tmpfile="$(mktemp)"

if [ -n "$*" ]; then
    echo "$@"
else
    sed 's/#.*//; s/:/ /' "$srcdir/../setup/repos.txt"
fi |
grep -vi -e bash-tools \
         -e playlist \
         -e '^[[:space:]]*$' |
while read -r repo dir; do
    if [ -z "$dir" ]; then
        dir="$(tr '[:upper:]' '[:lower:]' <<< "$repo")"
    fi
    if ! [ -d "../$dir" ]; then
        timestamp "WARNING: repo dir $dir not found, skipping..."
        continue
    fi
    if [ $# -gt 0 ]; then
        echo "$@" | tr '[:space:]' '\n'
    else
        sed 's/#.*//; /^[[:space:]]*$/d' "$srcdir/../setup/files.txt"
    fi |
    while read -r filename; do
        if [ "$filename" = .gitignore ]; then
            continue
        fi
        target="../$dir/$filename"
        if [ -f "$target" ] || [ -n "${NEW:-}" ]; then
            :
        else
            continue
        fi
        if [ -f "$filename" ]; then
            perl -pe "s/(devops-)*bash-tools/$repo/i" "$filename" > "$tmpfile"
            tmpfile_checksum="$(cksum "$tmpfile" | awk '{print $1}')"
            target_checksum="$(cksum "$target" | awk '{print $1}')"
            if [ "$tmpfile_checksum" = "$target_checksum" ]; then
                log "Skipping Config Sync for file due to same checksum: $filename"
                continue
            fi
            if ! QUIET=1 "$srcdir/../bin/diff_line_threshold.sh" "$filename" "$target"; then
                timestamp "Skipping Config Sync for file due to large diff: $filename"
                continue
            fi
            mkdir -pv "${target%/*}"
            timestamp "Syncing $filename -> $target"
            mv "$tmpfile" "$target"
        else
            timestamp "File not found: $filename. Skipping..."
        fi
    done
    direnv allow "../$dir"
done
