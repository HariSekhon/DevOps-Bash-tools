#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-07-21 11:36:49 +0100 (Tue, 21 Jul 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# set the Track number metadata on mp3 files in the order that they are given
#
# eg. mp3_renumber *.mp3
#
# (*.mp3 simply works if the mp3 files are already in the correct lexical order they will receive the right metadata track order which some apps like Books.app need)
#
#
# If you want to set subdirectories order, eg if you have audiobooks with CD1, CD2 subdirectories you can do this instead but beware not to do this at the root of your MP3 collection or it'll mess up your metadata between unrelated albums:
#
# find . -maxdepth 2 -iname '*.mp3' | { i=0; while read mp3; do ((i+=1)); id3v2 -T $i "$mp3"; done; }
#
# see mp3_track_metadata_reorder.sh for a safer way with preview and prompt

mp3_renumber(){
    local i=0
    for x in "$@"; do
        ((i+=1))
        id3v2 --track "$i" "$x"
    done
}
