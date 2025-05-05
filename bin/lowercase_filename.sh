#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-04-26 02:44:42 +0800 (Sat, 26 Apr 2025)
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
Renames a file to lowercase, using an intermediate file to work around case insensitive filesystems like on macOS
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<file>"

help_usage "$@"

num_args 1 "$@"

filename="$1"

if ! [ -f "$filename" ]; then
    die "File not found: $filename"
fi

filename_lowercase="$(tr '[:upper:]' '[:lower:]' <<< "$filename")"

tmpfile="$filename.lowercase.tmp"

mv -fv "$filename" "$tmpfile"

mv -fv "$tmpfile" "$filename_lowercase"
