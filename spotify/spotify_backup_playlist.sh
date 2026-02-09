#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: harisekhon
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
. "$srcdir/lib/spotify.sh"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/git.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Backs up a given Spotify playlist to text files in both Spotify URI and human readable formats

Spotify track URI format can be copied and pasted back in to Spotify to restore a playlist to a previous state
(for example if you accidentally deleted a track and didn't do an immediate Ctrl-Z / Cmd-Z)

Spotify track URI format can also be combined with spotify_add_to_playlist.sh to restore or add to another playlist

Caches metadata locally in .spotify_metadata/ directory. Tracks playlist name to automatically rename playlist files
and playlist snapshot ID to avoid re-downloading playlists which haven't changed, reducing the number of Spotify API
calls and therefore the likelihood of hitting HTTP 429 Too Many Requests throttling errors

If a second argument is given with the Spotify Snapshot_ID, this avoids having to fetch the playlist's metadata,
greatly speeding up iterative downloads of all playlists

The environment variable SPOTIFY_PLAYLIST_FORCE_DOWNLOAD can be set to any value to force a playlist to redownload
and ignore the last downloaded snapshot ID optimization above

If the playlist name has changed Detects the playlist file is committed to Git, then calls:

    spotify_rename_playlist_files.sh

to rename the corresponding playlist, spotify and description files to match the current name and then restore the
changes on top of the rename so you can then git diff to see what has changed if anything aside from the rename itself

$usage_playlist_help

$usage_auth_help
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<playlist> [<playlist_id> <snapshot_id> <curl_options>]"

help_usage "$@"

min_args 1 "$@"

playlist="$1"
if [ "$playlist" = liked ] || [ "$playlist" = saved ]; then
    playlist="Liked Songs"
fi
liked(){
    [ "$playlist" = "Liked Songs" ]
}

playlist_id="${2:-}"
snapshot_id="${3:-}"

shift || :
shift || :
shift || :

spotify_user

if not_blank "${SPOTIFY_BACKUP_DIR:-}"; then
    backup_dir="$SPOTIFY_BACKUP_DIR"
elif [[ "$PWD" =~ playlist ]]; then
    backup_dir="$PWD"
else
    backup_dir="$PWD/playlists"
fi

# messes up output per line when iterating all playlists via spotify_backup_playlists.sh
#log "Backing up to directory: $backup_dir"

backup_dir_base="$backup_dir"
backup_dir_spotify_base="$backup_dir/spotify"
backup_dir_metadata="$backup_dir/.spotify_metadata"
unchanged_playlist=0

# if .path_mappings.txt exists in the backup directory, map playlist names to subdirs via regex.
# format: first column = directory name (tab-separated), rest of line = regex to match playlist name.
# spotify does not expose folder structure, so this recreates grouping (e.g. "Best of Year", "Mixes in Time").
# match is done with grep -E so regex is never re-interpreted by the shell (avoids injection if file is untrusted).
get_path_mapping_subdir(){
    local base_dir="$1"
    local playlist_name="$2"
    local mappings_file="$base_dir/.path_mappings.txt"
    [ -f "$mappings_file" ] || return 0
    local dir regex
    while IFS= read -r line; do
        line="${line%%#*}"
        line="$(printf '%s' "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        [ -z "$line" ] && continue
        dir="${line%%$'\t'*}"
        regex="${line#*$'\t'}"
        [ -z "$regex" ] && continue
        if grep -Eq -- "\\<$regex\\>" <<< "$playlist_name"; then
            echo "$dir"
            return 0
        fi
    done < "$mappings_file"
    return 0
}
export -f get_path_mapping_subdir

apply_path_mapping(){
    local playlist_name="$1"
    path_mapping_subdir="$(get_path_mapping_subdir "$backup_dir_base" "$playlist_name")"
    if [ -n "$path_mapping_subdir" ]; then
        backup_dir="$backup_dir_base/$path_mapping_subdir"
        backup_dir_spotify="$backup_dir_base/spotify/$path_mapping_subdir"
        mkdir -p "$backup_dir" "$backup_dir_spotify"
    else
        backup_dir="$backup_dir_base"
        backup_dir_spotify="$backup_dir_spotify_base"
    fi
}

if liked; then
    playlist_name="Liked Songs"
fi

mkdir -vp "$backup_dir"
mkdir -vp "$backup_dir_spotify"
mkdir -vp "$backup_dir_metadata"

if liked; then
    export SPOTIFY_PRIVATE=1
fi
spotify_token

SECONDS=0

# uses the local spotify/playlists.txt file cache as it's faster than iterating the API for all playlists
# with spotify_playlist_name_to_id.sh to find the ID of matching playlist name
playlist_name_to_id(){
    local playlist="$1"
    # spotify/playlists.txt is generated up front by spotify_backup_playlists.sh
    # before it calls this script against each playlist
    local playlists_cache="spotify/playlists.txt"
    if [ -f "$playlists_cache" ]; then
        playlist_id="$(
            awk -v name="$playlist" '
                {
                    id = $1
                    $1 = ""
                    sub(/^[[:space:]]+/, "")
                    if ($0 == name) {
                        print id
                        exit
                    }
                }
            ' "$playlists_cache"
        )"

        if [ -n "$playlist_id" ] && [[ "$playlist_id" =~ ^[A-Za-z0-9]{22}$ ]]; then
            #timestamp "cache hit: $playlist_id"
            echo "$playlist_id"
            return
        fi
    fi
    #timestamp "cache miss: processing to use API lookup"
    SPOTIFY_PLAYLIST_EXACT_MATCH=1 "$srcdir/spotify_playlist_name_to_id.sh" "$playlist"
}
export -f playlist_name_to_id

clean_trackname(){
    local artist_track="$1"
    sed '
        s/^[[:space:]]*-//;
        s/^[[:space:]]*//;
        s/[[:space:]]*$//
    ' <<< "$artist_track"
}
export -f clean_trackname

if liked; then
    echo -n "$playlist_name "

    filename="$("$srcdir/spotify_playlist_to_filename.sh" <<< "$playlist_name")"
    apply_path_mapping "$playlist_name"

    # Caching behaviour
    # if we pass the second arg snapshot ID just use that to save an API call
    if ! is_blank "$snapshot_id"; then
        liked_added_at="$snapshot_id"
    else
        liked_added_at="$("$srcdir/spotify_api.sh" "/v1/me/tracks?limit=1" | jq -r '.items[0].added_at')"
    fi
    liked_metadata_dir="$backup_dir_metadata/liked"
    mkdir -pv "$liked_metadata_dir"
    liked_added_cache="$liked_metadata_dir/added_at"
    if [ -f "$liked_added_cache" ] &&
       [ "$liked_added_at" = "$(cat "$liked_added_cache")" ] &&
       is_blank "${SPOTIFY_PLAYLIST_FORCE_DOWNLOAD:-}"; then
        echo -n '=> Latest Added Timestamp Unchanged'
    else
        echo -n "=> URIs "
        #trap_cmd "cd \"$backup_dir_spotify\" && git checkout \"$filename\" &>/dev/null"
        #"$srcdir/spotify_liked_tracks_uri.sh" "$@" | sort -f > "$backup_dir_spotify/$filename"
        #untrap
        # better to just use atomic moves so we can ./commit.sh even while this is running
        # without being prompted with net removals by partially completed downloads
        track_tmp="$(mktemp)"
        uri_tmp="$(mktemp)"
        #"$srcdir/spotify_liked_tracks_uri.sh" "$@" | sort -f > "$tmp"
        #mv -f -- "$tmp" "$backup_dir_spotify/$filename"
        "$srcdir/spotify_liked_uri_artist_track.sh" |
        while read -r uri track; do
            if ! validate_spotify_uri "$uri" &>/dev/null &&
               ! is_local_uri "$uri" ; then
                die "Invalid Spotify URI returned: '$uri', for track: $track"
            fi
            echo "$uri" >> "$uri_tmp"
            clean_trackname "$track" >> "$track_tmp"
        done
        #mv -f "$track_tmp" "$backup_dir/$filename"
        #mv -f "$uri_tmp" "$backup_dir_spotify/$filename"
        # XXX: sort the Liked URI and track orderings - although this breaks the fidelity between the playlist <=> spotify/playlist formats,
        #      it's necessary to avoid recurring large diffs as Spotify seems to change the output ordering of this
        sort -f "$track_tmp" > "$backup_dir/$filename"
        sort -f "$uri_tmp" > "$backup_dir_spotify/$filename"
        rm -f "$track_tmp"
        rm -f "$uri_tmp"
        # try to avoid hitting HTTP 429 rate limiting
        sleep 0.1
        num_track_uris="$(wc -l < "$backup_dir_spotify/$filename" | sed 's/[[:space:]]*//')"
        num_tracks="$(wc -l < "$backup_dir/$filename" | sed 's/[[:space:]]*//')"

        if [ "$num_tracks" != "$num_track_uris" ]; then
            die "ERROR: differing number of tracks ($num_tracks) vs URIs ($num_track_uris) detected for Liked Songs"
        fi

        echo -n "OK ($num_track_uris) => Tracks "
        #trap_cmd "cd \"$backup_dir\" && git checkout \"$filename\" &>/dev/null"
        #"$srcdir/spotify_liked_tracks.sh" "$@" | sort -f > "$backup_dir/$filename"
        #tmp="$(mktemp)"
        #"$srcdir/spotify_liked_tracks.sh" "$@" | sort -f > "$tmp"
        #mv -f -- "$tmp" "$backup_dir/$filename"
        #untrap
        echo "$liked_added_at" > "$liked_added_cache"
        echo -n 'OK'
    fi
else
    if ! is_blank "$playlist_id"; then
        playlist_name="$playlist"
    else
        playlist_id="$(playlist_name_to_id "$playlist")"
        # if we were passed a playlist_id instead of name as first arg to avoid one lookup,
        # do a reverse lookup to get the name
        playlist_name="$("$srcdir/spotify_playlist_id_to_name.sh" "$playlist_id" "$@")"
    fi

    echo -n "$playlist_name"

    filename="$("$srcdir/spotify_playlist_to_filename.sh" <<< "$playlist_name")"
    apply_path_mapping "$playlist_name"

    # XXX: bugfix for 'illegal byte sequence error' for weird unicode chars in the filename
    #filename="$(sed 's/[^[:alnum:][:space:]!"$&'"'"'()+,.\/:<_|–\∕-]/-/g' <<< "$filename")"

    #echo "Saving to filename: $filename"

    playlist_metadata_dir="$backup_dir_metadata/$playlist_id"
    mkdir -p "$playlist_metadata_dir"

    playlist_metadata_name_file="$playlist_metadata_dir/name"
    playlist_metadata_filename_file="$playlist_metadata_dir/filename"
    playlist_metadata_snapshot_id_file="$playlist_metadata_dir/snapshot_id"

    #playlist_json="$("$srcdir/spotify_playlist_json.sh" "$playlist_id")"

    # If we pass the second arg snapshot ID just use that to save an API call
    if is_blank "$snapshot_id"; then
        # optimization to pull only the fields we need without the first 100 tracks
        playlist_json="$("$srcdir/spotify_api.sh" "/v1/playlists/$playlist_id?fields=snapshot_id,description")"

        # debug code for when we hit HTTP 429 Too Many Requests back off errors
        #if [ -n "${SPOTIFY_DUMP_HEADERS:-}" ]; then
        #    "$srcdir/../bin/curl_auth.sh" -i "$url_base/$url_path" "$@" | sed '/^[[:space:]]*$/,$d' >&2
        #    exit 1
        #fi

        echo -n " => Description "

        description_file="$backup_dir/$filename.description"

        # playlist descriptions are HTML encoded
        jq -r '.description' <<< "$playlist_json" | tr -d '\n' | "$srcdir/../bin/htmldecode.sh" > "$description_file"

        if [ -f "$description_file" ]; then
            # if file is blank then no description is set, remove the useless file
            if ! [ -s "$description_file" ]; then
                rm -f -- "$description_file"
                echo -n "None"
            else
                echo -n "OK"
            fi
        fi

        snapshot_id="$(jq -r '.snapshot_id' <<< "$playlist_json" | tr -d '\n')"
    fi

    # renaming a playlist or changing its description also changes the snapshot ID,
    # not just adding/removing/reordering tracks, triggering a full re-download and rename handling logic
    if [ -f "$playlist_metadata_snapshot_id_file" ] &&
       [ "$snapshot_id" = "$(cat "$playlist_metadata_snapshot_id_file")" ] &&
       [ -f "$backup_dir/$filename" ] &&
       [ -f "$backup_dir_spotify/$filename" ] &&
       is_blank "${SPOTIFY_PLAYLIST_FORCE_DOWNLOAD:-}"; then
        echo -n ' => Snapshot ID unchanged'
        unchanged_playlist=1
    else
        # reset to the last good version to avoid having partial files which will offer bad commits of removed tracks
        echo -n " => URIs "
        #trap_cmd "cd \"$backup_dir_spotify\" && git checkout \"$filename\" &>/dev/null"
        #"$srcdir/spotify_playlist_tracks_uri.sh" "$playlist_id" "$@" > "$backup_dir_spotify/$filename"
        track_tmp="$(mktemp)"
        uri_tmp="$(mktemp)"
        #"$srcdir/spotify_playlist_tracks_uri.sh" "$playlist_id" "$@" > "$tmp"
        #mv -f "$tmp" "$backup_dir_spotify/$filename"
        #untrap
        "$srcdir/spotify_playlist_tracks_uri_artist_track.sh" "$playlist_id" "$@" |
        # TODO: consider replacing this with a tee to two streaming commands to avoid so many executions
        while read -r uri track; do
            if ! validate_spotify_uri "$uri" &>/dev/null &&
               ! is_local_uri "$uri" ; then
                die "Invalid Spotify URI returned: '$uri', for track: $track"
            fi
            echo "$uri" >> "$uri_tmp"
            clean_trackname "$track" >> "$track_tmp"
        done
        mv -f "$track_tmp" "$backup_dir/$filename"
        mv -f "$uri_tmp" "$backup_dir_spotify/$filename"
        # try to avoid hitting HTTP 429 rate limiting
        sleep 0.1
        num_track_uris="$(wc -l < "$backup_dir_spotify/$filename" | sed 's/[[:space:]]*//')"
        num_tracks="$(wc -l < "$backup_dir/$filename" | sed 's/[[:space:]]*//')"

        if [ "$num_tracks" != "$num_track_uris" ]; then
            die "ERROR: differing number of tracks ($num_tracks) vs URIs ($num_track_uris) detected for playlist: $playlist"
        fi

        echo -n "OK ($num_track_uris) => Tracks "

        # reset to the last good version to avoid having partial files which will offer bad commits of removed tracks
        # no longer needed as we use > tmp && atomic move below now instead since it's cleaner
        #trap_cmd "cd \"$backup_dir\" && git checkout \"$filename\" &>/dev/null"
        #"$srcdir/spotify_playlist_tracks.sh" "$playlist_id" "$@" > "$backup_dir/$filename"
        #untrap

        # better to just use atomic moves so we can ./commit.sh even while this is running
        # without being prompted with net removals by partially completed downloads
        #tmp="$(mktemp)"
        # sometimes there are tracks that have blank names due to spotify data issues
        #"$srcdir/spotify_playlist_tracks.sh" "$playlist_id" "$@" | sed '/^[[:space:]]*$/d' > "$tmp"
        #"$srcdir/spotify_playlist_tracks.sh" "$playlist_id" "$@" > "$tmp"
        #mv -f "$tmp" "$backup_dir/$filename"
        echo -n 'OK'

        old_filename="$(if [ -f "$playlist_metadata_filename_file" ]; then cat "$playlist_metadata_filename_file"; fi)"

        if not_blank "$old_filename" &&
           [ "$backup_dir/$filename" != "$backup_dir/$old_filename" ]; then

            echo -n " => playlist RENAMED"

            # with path mapping, renames are under base: Subdir/ and spotify/Subdir/; run from backup base
            if [ -n "${path_mapping_subdir:-}" ]; then
                cd "$backup_dir_base"
            else
                cd "$backup_dir"
            fi

            # if we're in a git repo and the old filename is git managed, then rename it
            #
            # optionally using a local rename.sh script if present - useful script hook which could have
            # some more specific handling of corresponding files under management - *.description, spotify/ or
            # .spotify/metadata/ files
            #
            # in my case this just calls spotify_rename_playlist_files.sh in this repo so it's the same, but a
            # potentially useful hook script to leave in, and the rename.sh abstraction is simpler
            if is_in_git_repo &&
               is_file_tracked_in_git "$old_filename"; then
                echo -n " => updating files... "
                if [ -x ./rename.sh ]; then
                    ./rename.sh "$old_filename" "$filename" ${path_mapping_subdir:+$path_mapping_subdir}
                else
                    "$srcdir/../scripts/spotify_rename_playlist_files.sh" "$old_filename" "$filename" ${path_mapping_subdir:+$path_mapping_subdir}
                fi
            fi

            if [ -f "core_playlists.txt" ]; then
                #echo -n " => updating core_playlists.txt"
                tmp="$(mktemp)"
                awk -v id="$playlist_id" -v name="$playlist_name" '
                    # replace the rest of line (the playlist name) if the first column (the playlist ID) matches
                    $1 == id { $0 = $1 " " name }
                    { print }
                ' core_playlists.txt > "$tmp"
                mv "$tmp" core_playlists.txt
            fi

            cd -
        fi
        # save all the metadata for comparison in the next run
        echo "$playlist_name" > "$playlist_metadata_name_file"
        echo "$filename"      > "$playlist_metadata_filename_file"
        echo "$snapshot_id"   > "$playlist_metadata_snapshot_id_file"
        # try to avoid hitting HTTP 429 rate limiting
        sleep 0.1
    fi
fi
echo " => $SECONDS secs"
# used by HariSekhon/Spotify-Playlists scripts to remove the many lines of unchanged playlists output
# so I can see only what has changed and where I am spending time to optimize things
if [ "$unchanged_playlist" = 1 ] && ! is_blank "${QUIET_UNCHANGED_PLAYLISTS:-}"; then
    clear_previous_line
fi
