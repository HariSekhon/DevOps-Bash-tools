#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: circa 2006 (forked from .bashrc)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# ============================================================================ #
#                  B a s h   G e n e r a l   F u n c t i o n s
# ============================================================================ #

pg(){
    # don't want pgrep, want color coding
    # shellcheck disable=SC2009
    ps -ef |
    grep -i --color=yes "$@" |
    grep -v grep
}

checkprog(){
    if command -v "$1" &>/dev/null; then
        return 0
    else
        echo "$1 could not be found in path"
        return 1
    fi
}

pass(){
    read -r -s -p 'password: ' PASSWORD
    echo
    export PASSWORD
}

hr(){
    echo "# ============================================================================ #"
}

repeat(){
    local i n
    n="$1"
    shift
    if [ -z "$n" ]; then
        echo "usage: repeat N command args"
        return 1
    fi
    for ((i=1; i <= n; i++)); do
        "$@"
    done
}

loop(){
    while true; do
        eval "${*//\$/\\$}"
        sleep 1
    done
}

topcommands(){
    # first awk print $2 but my advanced history records `date '+%F %T'` in between number and command for $2 and $3, making command $4
    history |
    awk '{print $4}' |
    awk 'BEGIN {FS="|"} {print $1}' |
    sort |
    uniq -c |
    sort -n |
    tail -n "${1:-10}" |
    sort -nr
}
alias topcmds=topcommands

# easy quick find recursing down current directory tree
#
#f(){
#    [ -n "$*" ] || { echo "usage: f <partial_pattern>"; return 1; }
#    pattern=""
#    for x in $*; do
#        pattern+="*$x"
#    done
#    pattern+="*"
#    find -L . -iname "$pattern"
#}
#
# shellcheck disable=SC2032
f(){
    local grep=""
    # shellcheck disable=SC2013
    for x in $(sed 's/[^A-Za-z0-9]/ /g' <<< "$*"); do
        if [[ "$x" =~ [a-zA-Z0-9] ]]; then
            grep="$grep | grep -i --color=auto $x"
        fi
    done
    # times about the same
    #eval find -L . -type f -iname "\*$1\*" $grep
    eval find -L . -type f "$grep"
}

add_etc_host(){
    local host_line="$*"
    $sudo grep -q "^$host_line" /etc/hosts ||
    $sudo echo "$host_line" >> /etc/hosts
}

vihosts(){
    [ $EUID -eq 0 ] && sudo="" || sudo=sudo
    $sudo vim /etc/hosts
    $sudo pkill -1 dnsmasq
}

browser(){
    if [ -n "$BROWSER" ]; then
        "$BROWSER" "$@"
    elif [ -n "$APPLE" ]; then
        open "$@"
    fi
}

epoch2date(){
    if [ -n "$APPLE" ]; then
        date -r "$1"
    else
        date -d "@$1"
    fi
}

currentScreenResolution(){
    #xrandr | awk '/\*/ {print $1}'
    xdpyinfo  | awk '/dimensions/ {print $2}'
}

yy(){
    cal "$(date '+%Y')"
}

# ============================================================================ #

timestamp(){
    printf "%s" "$(date '+%F %T')  $*"
    [ $# -gt 0 ] && printf "\n"
}
alias tstamp=timestamp

timestampcmd(){
    local output
    output="$(eval "$@" 2>&1)"
    timestamp "$output"
}
alias tstampcmd=timestampcmd

# ============================================================================ #

bak(){
    # TODO: switch this to a .backupstore folder for keeping this stuff instead
    for filename in "$@"; do
        [ -n "$filename" ] || { echo "usage: bak filename"; return 1; }
        [ -f "$filename" ] || { echo "file '$filename' does not exist"; return 1; }
        [[ $filename =~ .*\.bak\..* ]] && continue
        local bakfile
        bakfile="$filename.bak.$(date '+%F_%T' | sed 's/:/-/g')"
        until ! [ -f "$bakfile" ]; do
            echo "WARNING: bakfile '$bakfile' already exists, retrying with a new timestamp"
            sleep 1
            bakfile="$filename.bak.$(date '+%F_%T' | sed 's/:/-/g')"
        done
        cp -av "$filename" "$bakfile"
    done
}

unbak(){
    # restores the most recent backup of a file
    for filename in "$@"; do
        #[ -n "$filename" -o "${filename: -4}" != ".bak" ] || { echo "usage: unbak filename.bak"; return 1; }
        [ -n "$filename" ] || { echo "usage: unbak filename"; return 1; }
        #[ -f "$filename" ] || { echo "file '$filename' does not exist"; return 1; }
        local bakfile
        # don't use -t switch, we want the newest by name, not one that got touched recently
        bakfile="$(find . -name "$filename.bak.*" 2>/dev/null | sort | tail -n 1)"
        echo "restoring $bakfile"
        cp -av "$bakfile" "$filename"
    done
}

orig(){
    if [ $# -lt 1 ]; then
        echo "usage: orig file1 file2 file3 ..."
        return 1
    fi
    for filename in "$@"; do
        [ -f "$filename" ] || { echo "file '$filename' does not exist"; return 1; }
        [ -f "$filename.org" ] && { echo "$filename.orig already exists, aborting..."; return 1; }
    done
    for filename in "$@"; do
        cp -av "$filename" "$filename.orig"
    done
}

unorig(){
    if [ $# -lt 1 ]; then
        echo "usage: unorig file1.orig file2.orig file3.orig ..."
        return 1
    fi
    for filename in "$@"; do
        if [ -z "$filename" ] || [ "${filename: -5}" != ".orig" ]; then
            echo "usage: unorig filename.orig"
            return 1
        fi
        if ! [ -f "$filename" ]; then
            echo "file '$filename' does not exist"
            return 1
        fi
    done
    for filename in "$@"; do
        cp -av "$filename" "${filename%.orig}"
    done
}

# ============================================================================ #

strLastIndexOf(){
    local str="$1"
    local substr="$2"
    local remainder="${str##*$substr}"
    local lastIndex=$((${#str} - ${#remainder}))
    echo $lastIndex
}

# ============================================================================ #

progs(){
    # not passing function f()
    # shellcheck disable=SC2033
    find "${@:-.}" -type f |
    grep -Evf ~/code_regex_exclude.txt |
    grep -v -e '/lib/' -e '.*-env.sh' -e '/tests/'
}

progs2(){
    # not passing function f()
    # shellcheck disable=SC2033
    find "${@:-.}" -type f -o -type l |
    grep -Evf ~/code_regex_exclude.txt
}

findpy(){
    # not passing function f()
    # shellcheck disable=SC2033
    find "${@:-.}" -type f -iname '*.py' -o -iname '*.jy' |
    grep -vf ~/code_regex_exclude.txt
}
