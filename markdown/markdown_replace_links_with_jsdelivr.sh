#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2026-02-11 17:58:27 -0300 (Wed, 11 Feb 2026)
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
. "$srcdir/lib/github.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Replaces local GitHub repo file links in the given markdown file(s) with JSDelivr CDN links

Handles Markdown and URL links in the format:

[Name](/path)

img src=\"/path\"

Explicit URLs are not converted yet
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<markdown_files>"

help_usage "$@"

#min_args 1 "$@"

process_markdown_file(){
    local filename="$1"
    local dirname
    local basename
    dirname="$(dirname "$filename")"
    basename="${filename##*/}"
    [ -f "$filename" ] || die "File not found: $filename"
    pushd "$dirname" &>/dev/null
    if ! is_git_repo; then
        die "Not inside a Git Repo - will not be able to determine GitHub repo name to construct JSDelivr URL"
    fi
    owner_repo="$(get_github_repo)"
    if is_blank "$owner_repo"; then
        die "Failed to determine GitHub repo for file: $filename"
    fi
    current_branch="$(current_branch)"
    sed -i "
        s|\\(img src=[\"']\\)/|\\1https://cdn.jsdelivr.net/gh/$owner_repo@$current_branch/|;
        s|\\([[^\\]].*](\\)/|\\1https://cdn.jsdelivr.net/gh/$owner_repo@$current_branch/|;
    " "$basename"
    popd &>/dev/null
}

if [ $# -eq 0 ]; then
    process_markdown_file README.md
else
    for filename; do
        process_markdown_file "$filename"
    done
fi
