#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: circa 2006 - 2012 (forked from .bashrc)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# ============================================================================ #
#                                  S c r e e n
# ============================================================================ #

# quickly open new screen terminal in the same $PWD
alias scbash="screen bash"

sc(){
    checkprog screen || return 1
    isscreen && { echo "I am already in a screen, aborting"; return 1; }
    screen -wipe
    local session=main
    local detached_screens
    detached_screens="$(screen -ls | grep Detached)"
    if [ -n "$detached_screens" ] &&
       [ "$(wc -l <<< "$detached_screens" | awk '{print $1}')" = 1 ]; then
        session="$(awk '{print $1;exit}' <<< "$detached_screens")"
    fi
    screen -aARRD -S "$session" "$@"
}

screencmd(){
    screen -X "$@"
}

screensleep(){
    screen "$@"
    sleep 0.1
}

alias scnum="screen -X number"

#screen_get_pid(){
#    # Mac ps doesn't have --noheaders
#    ps -p "${PPID}" -o ppid | tail -n +2 | sed 's/[[:space:]]//g'
#}
#
#screen_get_session_name(){
#    local ppid
#    ppid="$(screen_get_pid)"
#    screen -ls | awk "/^[[:blank:]]$ppid/{print \$1}" | cut -d. -f2
#}

# needs modern version of screen for -Q switch - on Mac you must brew install screen to get recent version, then start new screen
# when installing GNU screen you will lose Mac's screen since /usr/bin/screen uses a different /var/folders/...../.screen directory for screen sessions
screen_renumber_windows(){
    local windowlist
    windowlist="$(screen -Q windows | grep -Eo '(^|[[:blank:]])[[:digit:]]+')"
    i=0
    for windownum in $windowlist; do
        screen -p "$windownum" -X number "$i"
        ((i+=1))
    done
}
alias screnum=screen_renumber_windows

screenbuf(){
    local tmp
    tmp="$(mktemp /tmp/screen-exchange.XXXXXX)"
    cat > "$tmp"
    screen -X readbuf "$tmp"
    rm -- "$tmp";
}
alias sb=screenbuf

sh_server_real(){
    for x in "$@"; do
        echo "sh server real $x | i $x|Weight|Total"
    done |
    tee /dev/stderr |
    screenbuf
    echo
}
alias fsr=sh_server_real
alias ssr=sh_server_real

# this idea's is a bust so far...
#function c(){
#    screen -t "$@" bash -c ". ~/.bashrc && eval $@"
#}
