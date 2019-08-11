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

vihosts(){
    [ $EUID -eq 0 ] && sudo="" || sudo=sudo
    $sudo vim /etc/hosts
    $sudo pkill -1 dnsmasq
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
    find "${@:-.}" -type f |
    grep -Evf ~/code_regex_exclude.txt |
    grep -v -e '/lib/' -e '.*-env.sh' -e '/tests/'
}

progs2(){
    find "${@:-.}" -type f -o -type l |
    grep -Evf ~/code_regex_exclude.txt
}

findpy(){
    find "${@:-.}" -type f -iname '*.py' -o -iname '*.jy' |
    grep -vf ~/code_regex_exclude.txt
}
