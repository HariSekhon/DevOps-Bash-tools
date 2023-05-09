#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-07-03 17:14:30 +0100 (Fri, 03 Jul 2020)
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

# shellcheck disable=SC2034
usage_description="
Iterates over and commits all downloaded Spotify playlists in \$PWD or playlists/ directory,
showing diffs and then committing each in turn

First shows only the net removals in standard Spotify URIs + Track Name for a playlist
to check if anything has been lost from a playlist (additions don't need as much scrutiny)

Drastically reduces net removals list for human review by omitting duplicate URI removals
(checks if URI is present in the spotify format playlist) or URI replacements for same song
(either URI remapping or single vs album)

If there are no net removals then auto-commits the playlist

Otherwise shows the list of net removals in both Spotify URI and Track name formats
followed by the full human readable playlist diff and spotify URI diff underneath

If satisfactory, hitting enter at the end of the playlist diff will commit both
the Spotify URI and human readable playlist simultaneously

Requires DevOps-Perl-tools to be in \$PATH for diffnet.pl
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<playlist>]"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC1090,SC1091
#. "$srcdir/.bash.d/git.sh"

help_usage "$@"

commit_playlist(){
    playlist="$1"
    if ! [ -f "$playlist" ] ||
       ! [ -f "spotify/$playlist" ]; then
        return
    fi
    timestamp "Checking playlist: $playlist"
    if git status -s "$playlist" "spotify/$playlist" | grep -q '^[?A]'; then
        git add "$playlist" "spotify/$playlist"
        git ci -m "added $playlist spotify/$playlist" "$playlist" "spotify/$playlist"
        return
    fi
    if ! git status -s "$playlist" "spotify/$playlist" | grep -q '^.M'; then
        return
    fi
    net_removals="$(find_net_removals "$playlist")"
    if [ -z "$net_removals" ]; then
        echo "Auto-committing playlist '$playlist' as no net removals"
        echo
        git add "$playlist" "spotify/$playlist"
        git ci -m "updated $playlist spotify/$playlist" "$playlist" "spotify/$playlist"
        echo
        return
    fi
    echo "Net Removals from playlist '$playlist' (could be replaced with different track version):"
    echo
    echo "$net_removals"
    echo
    read -r -p "Hit enter to see full human and spotify diffs or Control-C to exit"
    echo
    git diff "$playlist" "spotify/$playlist"
    echo
    read -r -p "Hit enter to commit playlist '$playlist' or Control-C to exit"
    echo
    git add "$playlist" "spotify/$playlist"
    git ci -m "updated $playlist"
}

find_net_removals(){
    local playlist="$1"
    # stop grep breaking everything when no removals
    git diff "spotify/$playlist" |
    diffnet.pl |
    { grep ^- || :; } |
    sed 's/^-//' |
    while read -r uri; do
        if grep -Fxq "$uri" "spotify/$playlist"; then
            if [ -n "${VERBOSE:-}" ]; then
                echo "skipping removed duplicate URI '$uri' which is present in spotify/$playlist" >&2
            fi
            continue
        fi
        track="$("$srcdir/../spotify/spotify_uri_to_name.sh" <<< "$uri")"
        if grep -Fxq "$track" "$playlist"; then
            if [ -n "${VERBOSE:-}" ]; then
                echo "skipping removed URI for track '$track' which is found in $playlist (must have been replaced with a different URI)" >&2
            fi
            continue
        fi
        printf '%s\t%s\n' "$uri" "$track"
    done
}

if [ $# -gt 0 ]; then
    for playlist in "$@"; do
        commit_playlist "$playlist"
    done
else
    if ! [[ "$PWD" =~ playlists ]]; then
        cd playlists
    fi
    git status --porcelain |
    { grep '^.M' || :; } |
    sed 's/^...//; s,spotify/,,; s/^"//; s/"$//' |
    sort -u |
    while read -r playlist; do
        commit_playlist "$playlist"
    done
fi
