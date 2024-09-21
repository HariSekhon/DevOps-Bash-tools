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
Syncs GitHub Actions CI/CD workflows in this repo to all adjacent repo checkouts listed in ../setup/repos.txt

Quick way of updating GitHub Actions CI/CD workflows between repos

and then using ../git/github_foreach_repo.sh to commit them
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<workflow_yaml_1> <workflow_yaml_2> ...]"

help_usage "$@"

cd "$srcdir/../.github/workflows"

tmpfile="$(mktemp)"

sync_file(){
    local filename="$1"
    local repo="$2"
    local dir="${3:-}"
    if [ -z "$dir" ]; then
        dir="$repo"
    fi
    dir="$(tr '[:upper:]' '[:lower:]' <<< "$dir")"
    if ! [ -d "$srcdir/../../$dir" ]; then
        timestamp "WARNING: repo dir $srcdir/../../$dir not found, skipping..."
        return 0
    fi
    target="$srcdir/../../$dir/.github/workflows/$filename"
    targetdir="${target%/*}"
    mkdir -p -v "$targetdir"
    if [ -f "$target" ]; then
        perl -p -e "s/(DevOps-)?Bash-tools/$repo/i" "$filename" > "$tmpfile"
        tmpfile_checksum="$(cksum "$tmpfile" | awk '{print $1}')"
        target_checksum="$(cksum "$target" | awk '{print $1}')"
        if [ "$tmpfile_checksum" = "$target_checksum" ]; then
            log "Skipping GitHub Actions CI/CD Config Sync for file due to same checksum: $filename"
            return 0
        fi
        if ! QUIET=1 "$srcdir/../bin/diff_line_threshold.sh" "$filename" "$target"; then
            timestamp "Skipping GitHub Actions CI/CD Config Sync for file due to large diff: $filename"
            return 0
        fi
        timestamp "Syncing $filename -> $target"
        mv "$tmpfile" "$target"
    else
        log "File not found: $target. Skipping..."
    fi
}

sed 's/#.*//; s/:/ /' "$srcdir/../setup/repos.txt" |
grep -v -e bash-tools \
        -e '^[[:space:]]*$' |
while read -r repo dir; do
    if [ $# -gt 1 ]; then
        for filename in "$@"; do
            sync_file "$filename" "$repo" "$dir"
        done
    else
        for filename in *.yaml; do
            sync_file "$filename" "$repo" "$dir"
        done
    fi
done
