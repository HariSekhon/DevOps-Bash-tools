#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: sed 's/^[^[:space:]]*[[:space:]]*//' $playlists/playlists.txt
#
#  Author: Hari Sekhon
#  Date: 2020-06-24 17:39:04 +0100 (Wed, 24 Jun 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<playlist_name>"

# shellcheck disable=SC2034
usage_description="
Normalizes a Spotify playlist name provided as arg(s) or stdin to a valid filename
"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

help_usage "$@"

normalize(){
    # replace forward slash with unicode version
    tr '/' '∕'
    #tr '/[:space:]' '_'
    # requires Perl 5.10+
    #perl -pe 's/[\h\/]/_/g'
    #perl -pe 's/!//g'
    #perl -pe 's/[^\w\v-]/_/g'
}

if [ -n "$*" ]; then
    normalize <<< "$*"
else
    normalize  # from stdin
fi
