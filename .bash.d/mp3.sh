#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-07-21 11:36:49 +0100 (Tue, 21 Jul 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# set the Track number metadata on mp3 files in the order that they are given
# see much better mp3_set_track_order.sh at top level of this repo now
#mp3_renumber(){
#    local i=0
#    for x in "$@"; do
#        ((i+=1))
#        id3v2 --track "$i" "$x"
#    done
#}

mp3info(){
    find "${@:-.}" -type f -iname '*.mp3' |
    head -n 1 |
    while read -r filename; do
        mediainfo "$filename"
    done
}

mp3infotail(){
    find "${@:-.}" -type f -iname '*.mp3' |
    tail -n 1 |
    while read -r filename; do
        mediainfo "$filename"
    done
}

mp3infoheadtail(){
    find "${@:-.}" -type f -iname '*.mp3' |
    sed -n '1p;$p' |
    while read -r filename; do
        mediainfo "$filename"
    done
}

mp3set(){
    if [ $# != 2 ]; then
        echo "usage: mp3set <artist> <album>"
        return 1
    fi
    local artist="$1"
    local album="$2"
    mp3_set_artist.sh "$artist"
    mp3_set_album.sh  "$album"
    mp3_set_track_order.sh
    mp3_set_track_name.sh
}
