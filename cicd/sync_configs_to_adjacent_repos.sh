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

cd "$srcdir/.."

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
        echo "WARNING: repo dir $dir not found, skipping..."
        continue
    fi
    sed 's/#.*//; /^[[:space:]]*$/d' "$srcdir/../setup/files.txt" |
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
        mkdir -pv "${target%/*}"
        if [ -f "$filename" ]; then
            echo "syncing $filename -> $target"
            perl -pe "s/(devops-)*bash-tools/$repo/i" "$filename" > "$target"
        else
            echo "file not found: $filename. Skipping..."
        fi
    done
done
