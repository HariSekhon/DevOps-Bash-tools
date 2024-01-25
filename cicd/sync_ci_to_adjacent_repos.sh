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

sed 's/#.*//; s/:/ /' "$srcdir/../setup/repos.txt" |
grep -vi -e bash-tools \
         -e jenkins \
         -e github-actions \
         -e playlist \
         -e sql-scripts \
         -e sql-keywords \
         -e teamcity \
         -e '^[[:space:]]*$' |
while read -r repo dir; do
    if [ -z "$dir" ]; then
        dir="$(tr '[:upper:]' '[:lower:]' <<< "$repo")"
    fi
    # filtered above
    #if ls -lLdi "$dir" "$srcdir" | awk '{print $1}' | uniq -d | grep -q .; then
    #    echo "skipping $dir as it's our directory"
    #    continue
    #fi
    if ! [ -d "../$dir" ]; then
        echo "WARNING: repo dir $dir not found, skipping..."
        continue
    fi
    if [ -n "$*" ]; then
        for filename in "$@"; do
            echo "$filename"
        done
    else
        sed 's/#.*//; /^[[:space:]]*$/d' "$srcdir/../setup/ci.txt"
    fi |
    while read -r filename; do
        target="../$dir/$filename"
        if [ -f "$target" ] || [ -n "${NEW:-}" ]; then
            :
        else
            continue
        fi
        mkdir -pv "${target%/*}"
        echo "syncing $filename -> $target"
        perl -pe "s/(?<!- )(devops-)*bash-tools/$repo/i" "$filename" > "$target"
        #if [ "$repo" = "nagios-plugins" ]; then
        #    perl -pi -e 's/(^[[:space:]]+make ci$)/\1 ci zookeeper-retry/' "$target"
        #fi
    done
done
"$srcdir/../.github/workflows/sync_to_adjacent_repos.sh" "$@"
