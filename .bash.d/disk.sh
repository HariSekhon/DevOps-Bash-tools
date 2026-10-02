#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: circa 2006 (forked from .bashrc)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn
#  and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# ============================================================================ #
#                      B a s h   D i s k  F u n c t i o n s
# ============================================================================ #

# Disk & Filesystem Functions - split off from functions.sh

bash_tools="${bash_tools:-$(dirname "${BASH_SOURCE[0]}")/..}"

# shellcheck disable=SC1090,SC1091
. "$bash_tools/.bash.d/os_detection.sh"

cddir(){
    cd "$(dirname "$1")" || return 1
}

new(){
    if [ $# -eq 2 ]; then
        title "${2#modules/}"
    else
        title "$1"
    fi
    command new.pl "$@"
    title "$LAST_TITLE"
}

rmdirempty(){
    find "${1:-.}" -type d -empty -exec rmdir "{}" \;
}

dfwatch(){
    timestamp "Checking disk usage every 30 minutes"
    echo
    while true; do
        timestamp "Disk Usage:"
        df -h "${@:-.}"
        sleep 1800
    done
}
alias dfw=dfwatch

dum(){
    du -max "${@:-.}" |
    sort -k1n |
    tail -n 10000
}

findup(){
    local arg="$1"
    current_dir="${PWD:-$(pwd)}"
    while [ "$current_dir" != "" ]; do
        if [ -e "$current_dir/$arg" ]; then
            echo "$current_dir/$arg"
            return 0
        fi
        current_dir="${current_dir%/*}"
    done
    echo "Not found in above path: $arg" >&2
    return 1
}

cdup(){
    local arg="$1"
    cd "$(findup "$arg")" || return 1
}

lld(){
    {
        local target="$1"
        ls -ld "$target"
        [ "$target" = "/" ] && return
        lld "$(dirname "$target")"
    } | column -t
}

resolve_symlinks(){
    local readlink=readlink
    if is_mac; then
        if type -P greadlink &>/dev/null; then
            readlink=greadlink
        else
            readlink=""
        fi
    fi
    if [ -z "$readlink" ]; then
        echo "$*"
        return
    fi
    for x in "$@"; do
        "$readlink" -m "$x"
    done
}

# for all files listed, return the highest directory
# useful for pushd to the right git root following symlinks before doing git diff and commmits,
# used by gitu() in git.sh which is called in inline vimrc 'nmap ;;'
basedir(){
    local dir_list=""
    for x in "$@"; do
        dir_list="$dir_list $(dirname "$x")"
    done
    # assumes they share the same base and that the shortest one will be right
    # could put more comparison here and return error if not
    local output
    output="$(tr ' ' '\n'  <<< "$dir_list" | grep -v '^[[:space:]]*$' | sort | head -n 1)"
    if [ -z "$output" ]; then
        echo "ERROR: empty basedir"
        return 1
    fi
    echo "$output"
}

strip_basedirs(){
    local basedir="$1"
    shift
    while read -r filename; do
        filename="${filename#"${basedir%%/}"/}"
        filename="${filename##/}"
        echo "$filename"
    done <<< "$@"
}

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
    for x in "${@//[^A-Za-z0-9_-]/.}"; do
        if [[ "$x" =~ [a-zA-Z0-9._-] ]]; then
            grep="$grep | grep -i --color=auto $x"
        fi
    done
    # times about the same
    #eval find -L . -type f -iname "\*$1\*" $grep
    eval find -L . -type f "$grep"
}

# quick find and ls -lh each file
fl(){
    f "$@" |
    while read -r line; do
        ls -lh "$line"
    done
}

fll(){
    local grep=""
    # shellcheck disable=SC2013
    for x in "${@//[^A-Za-z0-9_-]/.}"; do
        if [[ "$x" =~ [a-zA-Z0-9._-] ]]; then
            grep="$grep | grep -i --color=auto $x"
        fi
    done
    # times about the same
    #eval find -L . -type f -iname "\*$1\*" $grep
    eval find -L . -type f -exec ls -lh {} \\\; "$grep"
}

foreachfile(){
    # not passing function f()
    # shellcheck disable=SC2033
    find . -type f -maxdepth 1 |
    while read -r file; do
        [ ! -f "$file" ] && continue
        [ -b "$file"   ] && continue
        [ -c "$file"   ] && continue
        [ -d "$file"   ] && continue
        [ -p "$file"   ] && continue
        [ -S "$file"   ] && continue
        [ -L "$file"   ] && continue
        "$@"
    done
}

# file which
fw(){
    local path
    for x in "$@"; do
        path="$(which "$x")"
        if [ -z "$path" ]; then
            return 1
        fi
        file "$path"
        echo
        # shellcheck disable=SC2086
        ls -l $LS_OPTIONS "$path"
    done
}

cdwhich(){
    local path
    local directory
    if [ $# -ne 1 ]; then
        echo "usage: cdwhich programname"
        return 1
    fi
    path="$(which "$1")"
    if [ -z "$path" ]; then
        echo
        echo "$1 could not be found in \$PATH"
        return 1
    fi
    directory="$(dirname "$path")"
    if [ -z "$directory" ]; then
        echo "cannot find directory for $path"
        return 2
    fi
    echo "$directory"
    cd "$directory" || return 1
}

whichall(){
    local bin="$1"
    shift || :
    which -a "$bin" |
    while read -r bin; do
        echo -n "$bin: "
        "$bin" "$@"
    done
}

readlink(){
    if is_mac; then
        greadlink "$@"
    else
        command readlink "$@"
    fi
}

abspath(){
    readlink --canonicalize-missing "$1"
}
#abspath(){
#    if [ -z "$1" ]; then
#        echo "NO PATH GIVEN!"
#        return 1
#    fi
#    # shellcheck disable=SC2001
#    sed 's@^\./@'"$PWD"'/@;
#         s@^\([^\./]\)@'"$PWD"'/\1@;
#         s@^\.\./@'"${PWD%/*}"'/@;
#         s@/../@/@g;
#         s@/\./@/@g;
#         s@\(.*\/?\)\.\./?$@\1/@;
#         s@//@/@g;
#         s@/$@@;' <<< "$1"
#}

findpy(){
    # not passing function f()
    # shellcheck disable=SC2033
    find "${@:-.}" -type f -iname '*.py' -o -type f -iname '*.jy' |
    grep -vf ~/code_regex_exclude.txt
}
