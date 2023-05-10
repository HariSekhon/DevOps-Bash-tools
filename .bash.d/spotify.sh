#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-07-18 19:43:00 +0100 (Sat, 18 Jul 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# exports SPOTIFY_ACCESS_TOKEN so all the user private data spotify tools (../spotify_*.sh) can use it easily without re-prompting ia browser

spotifysession(){
    local SPOTIFY_ACCESS_TOKEN
    # this would prevent it from being exported to the shell as we want to make it easier to use full spotify tools
    #local SPOTIFY_ACCESS_TOKEN
    # SECONDS cannot be reset in the background in spotify_token_expire_timer() function
    SECONDS=0
    spotify_token_expire_timer &
    # defined in ../.bashrc
    # shellcheck disable=SC2154
    SPOTIFY_ACCESS_TOKEN="$(SPOTIFY_PRIVATE=1 "$bash_tools/spotify/spotify_api_token.sh")"
    export SPOTIFY_ACCESS_TOKEN
    timestamp "starting spotify session shell"
    "$SHELL"
    timestamp "exiting spotify session shell"
    unset SPOTIFY_ACCESS_TOKEN
}

spotify_token_expire_timer(){
    # we have the same $$ as our foreground shell
    local ppid=$$
    while true; do
        if [ "$SECONDS" -ge 3600 ]; then
            # XXX: this would never work as it'd only affect this background thread
            #unset SPOTIFY_ACCESS_TOKEN
            # instead kill the shell session and handle the unset in the spotifysession() function
            timestamp "Spotify Token expired - killing spotify shell"
            pgrep -P "$ppid" |
            # protect own shell so we can finish this code pipe
            grep -v $$ |
            # bash needs a -HUP signal, ignores TERM
            xargs kill -HUP
            break
        fi
        sleep 1
    done
}
