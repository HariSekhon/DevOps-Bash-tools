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
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# ============================================================================ #
#                  B a s h   G e n e r a l   F u n c t i o n s
# ============================================================================ #

bash_tools="${bash_tools:-$(dirname "${BASH_SOURCE[0]}")/..}"

# shellcheck disable=SC1090,SC1091
. "$bash_tools/.bash.d/os_detection.sh"

# Enables colourized return codes in prompt_func
# better leave it as the same as already set. This way a reload of bashrc doesn't change the mode
# could do retmode=${retmode:-off} but this is unnecessary overhead
#retmode=off
# safer to set it to off because otherwise it's possible to get in to a loop with set -u
retmode=${retmode:-off}
retmode(){
    if [ "$retmode" = "on" ]; then
        retmode=off
        echo "retmode off"
    else
        retmode=on
        echo "retmode on"
    fi
}

cddir(){
    cd "$(dirname "$1")" || return 1
}

jq(){
    command jq -CS "$@"
}

envg(){
    env |
    eval grep -i "$(for arg; do echo -n " -e '$arg'"; done)"
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

# generates bash autocompletion if not available
# sources bash autocompletion from local standardized path
autocomplete(){
    local name="$1"
    shift || :
    if [ -f ~/.bash.autocomplete.d/"$name.sh" ]; then
        # shellcheck disable=SC1090,SC1091
        . ~/.bash.autocomplete.d/"$name.sh"
    elif type -P "$name" &>/dev/null; then
        # doesn't work
        # shellcheck disable=SC1090,SC1091
        #source <(command "$name" completion bash)
        mkdir -pv ~/.bash.autocomplete.d
        command "$name" completion "$@" bash > ~/.bash.autocomplete.d/"$name.sh"
        # shellcheck disable=SC1090,SC1091
        . ~/.bash.autocomplete.d/"$name.sh"
    fi
}

pg(){
    # don't want pgrep, want color coding
    # shellcheck disable=SC2009
    ps -ef |
    grep -i --color=yes "$@" |
    grep -v grep
}

pstg(){
    # want splitting of options
    # shellcheck disable=SC2086
    pstree |
    grep -5 -i --color=always "$@" |
    less $LESS
}

# externalized to copy_to_clipboard.sh script
#copy_to_clipboard(){
#    if is_mac; then
#        cat | pbcopy
#    elif is_linux; then
#        cat | xclip
#    else
#        echo "ERROR: OS is not Darwin/Linux"
#        return 1
#    fi
#}

unalias clip &>/dev/null || :
# args are optional
# shellcheck disable=SC2120
clip(){
    if [ $# -gt 0 ]; then
        copy_to_clipboard.sh < "$1"
    else
        copy_to_clipboard.sh
    fi
}

deccp(){
    # shellcheck disable=SC2119
    decomment.sh "$@" |
    clip
}

decdiff(){
    diff <(decomment.sh "$1" | sed 's/[[:space:]]*$//') <(decomment.sh "$2" | sed 's/[[:space:]]*$//') "${@:3}"
}

rmdirempty(){
    find "${1:-.}" -type d -empty -exec rmdir "{}" \;
}

checkprog(){
    if type -P "$1" &>/dev/null; then
        return 0
    else
        echo "$1 could not be found in path"
        return 1
    fi
}

function count() {
    local total="$1"
    for ((i = total; i > 0; i--)); do
        sleep 1
        printf "Time remaining %d secs\r" "$i"
    done
    bell
}

dum(){
    du -max "${@:-.}" |
    sort -k1n |
    tail -n 10000
}

typer(){
    local alias_target
    local type_output
    for x in "$@"; do
        type_output="$(type "$x")"
        # shellcheck disable=SC2119
        alias_target="$(
            awk '/aliased to/{print $5}' <<< "$type_output" |
            unquote
        )"
        if [ -n "$alias_target" ]; then
            echo "$type_output"
            typer "$alias_target"
        else
            type "$x"
        fi
    done
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

lld(){
    {
        local target="$1"
        ls -ld "$target"
        [ "$target" = "/" ] && return
        lld "$(dirname "$target")"
    } | column -t
}

# shellcheck disable=SC2120
unquote(){
    sed '
        s/^[[:space:]]*[`'"'"'"]//;
        s/[`'"'"'"][[:space:]]*$//;
    ' "$@"
}

bell(){
    echo -e '\a'
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

# for all files listed, return the highest directory - useful for pushd to the right git root following symlinks before doing git diff and commmits, used by gitu() in git.sh which is called in inline vimrc 'nmap ;;'
basedir(){
    local dir_list=""
    for x in "$@"; do
        dir_list="$dir_list $(dirname "$x")"
    done
    # assumes they share the same base and that the shortest one will be right - could put more comparison here and return error if not
    local output
    output="$(tr ' ' '\n'  <<< "$dir_list" | grep -v '^[[:space:]]*$' | sort | head -n 1)"
    if [ -z "$output" ]; then
        echo "ERROR: empty basedir"
        return 1
    fi
    echo "$output"
}

toLower(){
    tr '[:upper:]' '[:lower:]'
}

toUpper(){
    tr '[:lower:]' '[:upper:]'
}

trim(){
    sed 's/^[[:space:]]*//; s/[[:space:]]*$//' "$@"
}

normalize_spaces(){
    # not variant of + \+ works on Mac
    #sed 's/[[:space:]]\+/ /'
    # flattens out newlines, which changes behaviour in scripts like check_git_commit_authors.sh
    #perl -pe 's/\s+/ /g'
    # horizontal newlines, don't match \n
    perl -pe 's/\h+/ /g'
}

remove_last_column(){
    awk '{$NF=""; print $0}'
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

user(){
    read -r -p 'user: ' USERNAME
    export USERNAME
    if [ -z "${PASSWORD:-}" ]; then
        pass PASSWORD
    fi
}

pass(){
    # doesn't echo, we can do better by making it star for each char
    #read -r -s -p 'password: ' PASSWORD
    # don't local PASSWORD or default case will not export PASSWORD, changing case to work around
    local password=""
    prompt="Enter password: "
    while IFS= read -p "$prompt" -r -s -n 1 char; do
        if [[ "$char" == $'\0' ]]; then
            break
        fi
        prompt='*'
        password="${password}${char}"
    done
    #passvar="${1:-PASSWORD}"
    for passvar in "${@:-PASSWORD}"; do
        export "$passvar"="$password"
    done
    echo
}

unpass(){
    unset PASSWORD
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

ptop(){
    if [ -z "$1" ]; then
        echo "usage: ptop program1 program2 ..."
        return 1
    fi
    local pids
    #pids="$(pgrep -f "$(sed 's/ /|/g' <<< "$*")")"
    pids="$(pgrep -f "${*// /|}")"
    local pid_args=()
    if is_mac; then
        # shellcheck disable=SC2001
        read -r -a pid_args <<< "$(sed 's/^/-pid /' <<< "$pids")"
    else
        # shellcheck disable=SC2001
        read -r -a pid_args <<< "$(sed 's/^/-p /' <<< "$pids")"
    fi
    if [ -z "${pids[*]}" ]; then
        echo "No matching programs found"
        return 1
    fi
    top "${pid_args[@]}"
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
    for x in "${@//[^A-Za-z0-9_-]/.}"; do
        if [[ "$x" =~ [a-zA-Z0-9._-] ]]; then
            grep="$grep | grep -i --color=auto $x"
        fi
    done
    # times about the same
    #eval find -L . -type f -iname "\*$1\*" $grep
    eval find -L . -type f "$grep"
}

dgrep(){
    local pattern="$*"
    # auto-exported in aliases.sh when iterating git repos
    # shellcheck disable=SC2154
    ls "$docs/"*"${pattern// /}"* 2>/dev/null
    # shellcheck disable=SC2046,SC2033
    grep -iER "$pattern" $(find ~/docs "$docs" -type f -maxdepth 1 2>/dev/null | grep -v '/\.')
}

diffl(){
    diff "$@" | less
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

# vim which
# vw() moved to vim.sh

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

add_etc_host(){
    local host_line="$*"
    # $sudo is set in .bashrc if needed
    # shellcheck disable=SC2154
    $sudo grep -q "^$host_line" /etc/hosts ||
    $sudo echo "$host_line" >> /etc/hosts
}

# vihosts() moved to vim.sh

proxy(){
    export proxy_host="${1:-${proxy_host:-localhost}}"
    export proxy_port="${2:-${proxy_port:-8080}}"
    export proxy_port_ssl="${3:-${proxy_port_ssl:-8443}}"
    export proxy_user="${4:-${proxy_user:-$USER}}"
    if [ -z "$proxy_password" ]; then
        read -r -s -p 'proxy password: ' proxy_password
    fi
    export http_proxy="http://$proxy_user:$proxy_password@$proxy_host:$proxy_port"
    export https_proxy="https://$proxy_user:$proxy_password@$proxy_host:$proxy_port_ssl"
    # MiniShift respects these next three
    export HTTP_PROXY="$http_proxy"
    export HTTPS_PROXY="$https_proxy"
    export NO_PROXY=".local,.localdomain,.intra,169.254.169.254" # works only on suffixes or IP addresses - ignore the EC2 Metadata API address
    export ftp_proxy="$http_proxy" # might need to replace protocol prefix here, would check, but who even uses ftp any more
    JAVA_NO_PROXY="$(sed 's/^/*/;s/,/|*/g' <<< "$NO_PROXY")"
    # strip the additions we just added off the end so that we don't end up with dups if running proxy more than once
    JAVA_OPTS="${JAVA_OPTS%%-Dhttp.proxyHost*}"
    export JAVA_OPTS="$JAVA_OPTS -Dhttp.proxyHost=$proxy_host -Dhttp.proxyPort=$proxy_port -Dhttp.proxyUser=$proxy_user -Dhttp.proxyPassword=$proxy_password -Dhttps.proxyHost=$proxy_host -Dhttps.proxyPort=$proxy_port_ssl -DnonProxyHosts='$JAVA_NO_PROXY'"
    export SBT_OPTS="$JAVA_OPTS"
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

wcbash(){
    # $github defined in aliases.sh
    # shellcheck disable=SC2154
    wc ~/.bashrc \
       ~/.bash_profile \
       ~/.bash_logout \
       ~/.alias* \
       ~/.aliases* \
       ~/.bashrc_dynamichosts \
       "$github/bash-tools/.bashrc" \
       "$github/bash-tools/.bash_profile" \
       "$github/bash-tools/.bash.d/"*.sh 2>/dev/null
}

epoch2date(){
    if is_mac; then
        date -r "$1"
    else
        date -d "@$1"
    fi
}

pdf(){
    if ! [[ "$1" =~ .*.pdf$ ]]; then
        echo "'$1' does not end in .pdf!"
        return 1
    fi
    if ! [ -f "$1" ]; then
        echo "file not found: $1"
        return 1
    fi
    if is_mac; then
        open "$1"
        return $?
    fi
    for x in acroread evince xpdf; do
        if type -P "$x" &>/dev/null; then
            echo "opening with $x..."
            "$x" "$1" &
            return $?
        fi
    done
    echo "Error cannot find acroread, evince or xpdf in PATH."
    return 1
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
    [ $# -gt 0 ] && printf '\n'
}
alias tstamp=timestamp

timestampcmd(){
    local output
    output="$("$@" 2>&1)"
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
        cp -av -- "$filename" "$bakfile"
    done
}

unbak(){
    # restores the most recent backup of a file
    for filename in "$@"; do
        #[ -n "$filename" -o "${filename: -4}" != ".bak" ] || { echo "usage: unbak filename.bak"; return 1; }
        [ -n "$filename" ] || { echo "usage: unbak filename"; return 1; }
        #[ -f "$filename" ] || { echo "file '$filename' does not exist"; return 1; }
        local bakfile
        local dirname
        dirname="$(dirname "$filename")"
        filename="${filename##*/}"
        # don't use -t switch, we want the newest by name, not one that got touched recently
        bakfile="$(find "$dirname" -path "*/$filename.bak.*" -o -path "*/$filename.*.bak" 2>/dev/null | sort | tail -n 1)"
        echo "restoring $bakfile"
        cp -av -- "$bakfile" "$dirname/$filename"
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
        cp -av -- "$filename" "$filename.orig"
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
        cp -av -- "$filename" "${filename%.orig}"
    done
}

# ============================================================================ #

strLastIndexOf(){
    local str="$1"
    local substr="$2"
    local remainder="${str##*"$substr"}"
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
    find "${@:-.}" -type f -iname '*.py' -o -type f -iname '*.jy' |
    grep -vf ~/code_regex_exclude.txt
}

# ============================================================================ #

ldapmaxuid(){
    ldapsearch -x -W "uidNumber=*" uidNumber |
    sed 's/#.*//' |
    grep -v "^[[:space:]]*$" |
    grep uidNumber |
    sort -k2n |
    tail -n1
}

ldapmaxuidgid(){
    ldapsearch -xW -x -W "(|(objectClass=posixAccount)(objectClass=posixGroup))" uidNumber gidNumber |
    sed 's/#.*//' |
    grep --color=auto -v "^[[:space:]]*$" |
    grep -R --color=auto "(uidNumber|gidNumber)" |
    sort -k2n |
    tail -n1
}
