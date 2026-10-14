#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  args: ../../playlists/spotify/Rocky
#
#  Author: Hari Sekhon
#  Date: 2020-06-25 22:28:51 +0100 (Thu, 25 Jun 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn
#  and optionally send me feedback to help steer this or other code I publish
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
Cvonerts Spotify URLs to URIs

Useful to work with offline playlist comparisons

For example:

    https://open.spotify.com/track/...

becomes:

    spotify:track:...

Reads args as strings or files or reads from stdin if no args are given
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<uri_or_files>]"

help_usage "$@"

convert(){
    while read -r url; do
        [ -z "$url" ] && continue
        if [[ "$url" =~ ^spotify:(track|album|artist|episode): ]]; then
            echo "$url"
        elif [[ "$url" =~ ^https?://open.spotify.com/(track|album|artist|episode)/(.*) ]]; then
            echo "spotify:${BASH_REMATCH[1]}:${BASH_REMATCH[2]}"
        else
            die "ERROR: invalid format encountered: $url"
        fi
    done
}

files=()
tmp="$(mktemp)"

for filename in "$@"; do
    if [ -f "$filename" ]; then
        files+=("$filename")
        shift || :
    elif [[ "$filename" =~ ^https://open.spotify.com/|^spotify: ]]; then
        echo "$filename" >> "$tmp"
        shift || :
    else
        break
    fi
done

if [ -s "$tmp" ]; then
    files+=("$tmp")
fi

if [ -n "${files[*]:-}" ]; then
    for filename in "${files[@]}"; do
        convert < "$filename"
    done
else
    convert  # read from stdin
fi
