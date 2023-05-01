#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: circa 2006 (forked from .bashrc)
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
#            R e v i s i o n   C o n t r o l  -  S u b v e r s i o n
# ============================================================================ #

# I don't use SVN any more so a lot of the convenient aliases for daily use are commented out

bash_tools="${bash_tools:-$(dirname "${BASH_SOURCE[0]}")/..}"

# shellcheck disable=SC1090,SC1091
. "$bash_tools/.bash.d/os_detection.sh"

# superceded by hg and then git pull
#alias u="svn up"
#alias sd="svn diff"
#alias svnl=svnlog
#alias svnr="svn revert"

# remapped to screen
#s(){ svn st "$@" | more; }
#stx(){ svn st "$@" | grep -v "^?"; }

isSvn(){
    local target=${1:-.}
    if [ -d "$target/.svn" ]; then
        return 0
    elif [ -f "$target" ] &&
         [ -d "$(dirname "$target")/.svn" ]; then
        return 0
    else
        return 1
    fi
}

svn(){
    if is_mac; then
        export stat_formatopt=f
    else
        export stat_formatopt=c
    fi
    local svn_owner
    for x in "$@"; do
        if [ -d "$x/.svn" ]; then
            local dir_tested=true
            svn_owner="$(stat -$stat_formatopt "%u" "$x/.svn")"
            if [ "$EUID" != "$svn_owner" ]; then
                echo "YOU ARE RUNNING SVN AS THE WRONG USER ON $x"
                return 1
            fi
        fi
    done
    if [ "$dir_tested" != "true" ]; then
        if [ -d "./.svn" ]; then
            svn_owner="$(stat -$stat_formatopt "%u" ./.svn)"
            if [ "$EUID" != "$svn_owner" ]; then
                echo "YOU ARE RUNNING SVN AS THE WRONG USER HERE"
                return 1
            fi
        fi
    fi
    command svn "$@"
}

svnst(){
    svn st "$@"
}

svnkw(){
    svn ps svn:keywords "LastChangedBy LastChangedDate Revision URL Id" "$@"
}

svnadd(){
    svn add -- "$@" &&
    svnkw "$@"
}

svni(){
    svn pe svn:ignore -- "${@:-.}"
}

svnaddci(){
    svnadd "$@" &&
    svn ci -m "added $*" -- "$@"
}

svnci() {
    local svncimsg=""
    for x in "$@"; do
        if svn st "$x" | grep -q "^[?A]"; then
            svncimsg+="$x, "
        fi
    done
    [ -z "$svncimsg" ] && return 1
    svncimsg="${svncimsg%, }"
    svncimsg="added $svncimsg"
    svn add -- "$@" &&
    svn ci -m "$svncimsg" "$@"
}

svnrm(){
    svn rm -- "$@" &&
    svn ci -m "removed $*" -- "$@"
}

svnrmf(){
    svn rm --force -- "$@" &&
    svn ci -m "removed $*" -- "$@"
}

svnrename(){
    svn up "$(dirname "$1")" "$(dirname "$2")"
    svn mv -- "$1" "$2" &&
    svn ci -m "renamed $1 to $2" -- "$1" "$2"
}

svnrename2(){
    local svn_url
    svn_url=$(svn info "$1" | grep "^URL: " | sed 's/^URL: //')
    [ -n "$svn_url" ] || return
    svn rename -m "renamed $1 to $2" -- "$svn_url" "$(dirname "$svn_url")/$2"
    svn up -- "$1" "$2"
}

svnmkdir(){
    svn mkdir --parents -- "$@" &&
    svn ci -m "created directory $*" -- "$@"
}

svnmv(){
    svn up "$(dirname "$1")" "$(dirname "$2")"
    svn mv -- "$1" "$2" &&
    svn ci -m "moved $1 to $2" -- "$1" "$2"
}

svnrevert(){
    svn revert -- "$@"
}

svnlog(){
    local args=()
    local args2=()
    until [ $# -lt 1 ]; do
        case "$1" in
            -*) args+=("$1")
                ;;
             *) args2+=("$1")
                ;;
        esac
        shift
    done
    svn up "${args2[@]}" &&
    read -r -p "press enter to see log" &&
    svn log "${args[@]}" "${args2[@]}" | less
}

svnu(){
    [ -n "$1" ] || { echo "ERROR: must supply arg"; return 1; }
    [ "$(svn diff -- "$@" | wc -l)" -gt 0 ] || return
    svn diff -- "$@" | more &&
    read -r &&
    svn ci -m "updated $*" -- "$@"
}

svne(){
    svn ps svn:executable on "$@"
}

svnec(){
    svne "$@";
    for x in "$@"; do
        svn ci -m "set executable on $x"
    done
}

svncommitauthors(){
    svn log |
    awk '/^r[[:digit:]]+[[:space:]]/ {print $3}' |
    sort |
    uniq -c |
    sort -k1nr
}

rmnonsvn(){
    svn st |
    grep "^?" |
    awk '{print $2}' |
    xargs rm -f --
}

svndifflast(){
    local rev=HEAD
    local rev_last=PREV
    if grep -q '^[[:digit:]]\+' <<< "$1"; then
        rev="$1"
        shift;
    fi
    if [ "$rev" != "HEAD" ]; then
        #let rev_last=$rev-1
        (( rev_last = rev - 1 ))
    fi
    svn diff -r "$rev_last:$rev" -- "$@" |
    more
}
#alias sdl=svndifflast

svndiff(){
    local filename="${1:-}"
    [ -n "$filename" ] || { echo "usage: svndiff filename"; return 1; }
    svn diff "$filename" > "/tmp/svndiff.tmp"
    diffnet.pl "/tmp/svndiff.tmp"
}

svndiffcumulative(){
    local url
    svn up
    url="$(svn info | awk '/^URL/ {print $2}')"
    HEAD="$(svn info | awk '/Revision/ {print $2}')"
    for x in $(eval echo "{25470..$HEAD}"); do
        ((y=x+1))
        echo -n "svn $x => $y: "
        svn diff -r -- "$x:$y" "$url"
    done
}
alias svndiffcum="svndiffcumulative"

svncommmitcount(){
    svn up
    svn log -r 25470:HEAD |
    grep -E "^r[[:digit:]]+ |" |
    wc
}
