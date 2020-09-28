#!/usr/bin/env bash
# shellcheck disable=SC2230
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
#                   E n v i r o n m e n t   V a r i a b l e s
# ============================================================================ #

# more environment variables defined next to the their corresponding aliases in aliases.sh

bash_tools="${bash_tools:-$(dirname "${BASH_SOURCE[0]}")/..}"

# shellcheck disable=SC1090
. "$bash_tools/.bash.d/os_detection.sh"

# similar to what zsh does by default
if [ -f ~/.bashenv ]; then
    # shellcheck disable=SC1090
    . ~/.bashenv
fi

#export DISPLAY=:0.0

#export TERM=xterm

export EDITOR=vim

export INPUTRC=~/.inputrc

# allow programs to use $LINES and $COLUMNS
export LINES
export COLUMNS

# ENV refers to the file that sh attempts to read as a startup file (done on my Mac OSX Snow Leopard)
# Needs the following line added to sudoers for ENV to be passed through on sudo su
#Defaults	env_keep += "ENV"
export ENV=~/.bashrc

# aterm doesn't support UTF-8 and you get horrible chars here and there
# so don't use utf and aterm together. xterm works ok with utf8 though
#export LANG=en_GB
#export LC_ALL=en_GB
#export LANG=C
#export LC_ALL=C
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
# didn't seem to work
#export LANG="en_GB.UTF-8"
#export LC_ALL="en_GB.UTF-8"

# Clever dynamic environment variables, set using var() function sourced between shells
export varfile=~/.bash_vars
# shellcheck disable=SC1090
[ -f "$varfile" ] && . "$varfile"

#export DISTCC_DIR="/var/tmp/portage/.distcc/"

# ============================================================================ #

if isMac; then
    #BROWSER=open
    unset BROWSER
elif type -P google-chrome &>/dev/null; then
    BROWSER=google-chrome
elif type -P firefox &>/dev/null; then
    BROWSER=firefox
elif type -P konqueror &>/dev/null; then
    BROWSER=konqueror
elif [ -n "${GOOGLE_CLOUD_SHELL:-}" ]; then
    :
else
    :
    #BROWSER=UNKNOWN
    #echo "COULD NOT FIND ANY BROWSER IN PATH"
fi

# don't export BROWSER on Mac, trigger python bug:
# AttributeError: 'MacOSXOSAScript' object has no attribute 'basename'
# from python's webbrowser library
if ! isMac; then
    export BROWSER
fi

var(){
    local var="${*%%=*}"
    local val="${*#*=}"
    if grep -i "export $var" "$varfile" &>/dev/null; then
        perl -pi -e 's/^export '"$var"'=.*$/export '"$var"'='"$val"'/' "$varfile"
    else
        echo "export $var=$val" >> "$varfile"
    fi
    export "$var"="$val"
}
vars(){
    "$EDITOR" "$varfile"
    chmod 0600 "$varfile"
    # shellcheck disable=SC1090
    . "$varfile"
}

unvar(){
    local var="${*%%=*}"
    [ -f "$varfile" ] || { echo "$varfile not found" ; return 1; }
    perl -pi -e 's/^export '"$var"'=.*\n$//' "$varfile"
    unset "$var"
}
