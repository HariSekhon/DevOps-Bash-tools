#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: harisekhon
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

# shellcheck disable=SC1090
. "$srcdir/lib/spotify.sh"

# shellcheck disable=SC2034
usage_description="
Backs up all public or privte Spotify playlists for a given user to text files in both Spotify and human readable formats

Spotify track URI format can be copied and pasted back in to Spotify to restore a playlist to a previous state
(for example if you accidentally deleted a track and didn't do an immediate Ctrl-Z / Cmd-Z)

For public playlists, \$SPOTIFY_USER be set in the environment or given as the first arg
For private playlists, the user is inferred from the authorized token

Requires \$SPOTIFY_ID and \$SPOTIFY_SECRET to be defined in the environment

Caveat: due to limitations of the Spotify API, by default works on public playlists.
For private playlists you must export SPOTIFY_PRIVATE=1 and preferably pre-generate the token in your shell to prevent repeated web authorization pop-ups:

export SPOTIFY_ACCESS_TOKEN=\"\$(\"$srcdir/spotify_api_token.sh\")\"
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<spotify_user> [<curl_options>]"

help_usage "$@"

spotify_user="${1:-${SPOTIFY_USER:-}}"

shift || :

if is_blank "$spotify_user" && is_blank "${SPOTIFY_PRIVATE:-}"; then
    usage "\$SPOTIFY_USER not defined and no first argument given, and not specified \$SPOTIFY_PRIVATE to infer from token"
fi

if not_blank "${SPOTIFY_BACKUP_DIR:-}"; then
    backup_dir="$SPOTIFY_BACKUP_DIR"
elif [[ "$PWD" =~ playlist ]]; then
    backup_dir="$PWD"
else
    backup_dir="$PWD/playlists"
fi

SECONDS=0
timestamp "Backing up Spotify playlists to $backup_dir"
echo >&2
mkdir -vp "$backup_dir"

spotify_token

# for spotify_backup_playlist.sh to inherit, saving executions to recalculate on each iteration
export SPOTIFY_BACKUP_DIR="$backup_dir"

# stop spotify_foreach_playlist.sh from printing the playlist name as this results in duplicate output
export SPOTIFY_FOREACH_NO_PRINT_PLAYLIST_NAME=1
export SPOTIFY_FOREACH_NO_NEWLINE=1

"$srcdir"/spotify_foreach_playlist.sh "$srcdir/spotify_backup_playlist.sh '{playlist_id}'" "$spotify_user" "$@"
if [ -n "${SPOTIFY_PRIVATE:-}" ]; then
    "$srcdir/spotify_backup_playlist.sh" liked "$@"
fi
echo >&2
timestamp "Spotify playlists backup finished in $SECONDS seconds"
