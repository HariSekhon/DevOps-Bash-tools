#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  args: < ../playlists/playlists.txt
#
#  Author: Hari Sekhon
#  Date: 2020-06-24 17:39:04 +0100 (Wed, 24 Jun 2020)
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

# shellcheck disable=SC2034
usage_description="
Normalizes a Spotify playlist name provided as arg(s) or stdin to a valid filename

Replaces invalid / dangerous characters with underscores
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<playlist_name>"

help_usage "$@"

#normalize(){
#    # replace forward slash with unicode version so we can store playlist files that look like the real thing
#    # but avoid the breakage caused by directory separator
#    tr '/' '∕'
#    #tr '/[:space:]' '_'
#    # requires Perl 5.10+
#    #perl -pe 's/[\h\/]/_/g'
#    #perl -pe 's/!//g'
#    #perl -pe 's/[^\w\v-]/_/g'
#}

sanitize_filename() {
    # replace forward slash with unicode version so we can store playlist files that look like the real thing
    # but avoid the breakage caused by directory separator
    tr '/' '∕' |
    perl -CS -Mutf8 -p -e '
        s{[\x00-\x09\x0B-\x1F\x7F]}{_}g;  # control chars except \n
        s{[^\p{Print}\p{Emoji}\n]}{_}g;   # non-printable, non-emoji, keep \n
    ' |
    if is_windows; then
        perl -CS -Mutf8 -p -e '
            s{[\\/:*?"<>|]}{_}g;  # Windows-invalid filename characters
            s/[ .]+$//;           # trailing space or dot (Windows)
        '
    else
        cat
    fi
}

if not_blank "$*"; then
    sanitize_filename <<< "$*"
else
    sanitize_filename  # from stdin
fi
