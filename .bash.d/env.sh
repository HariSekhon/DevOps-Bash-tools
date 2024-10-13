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
#                   E n v i r o n m e n t   V a r i a b l e s
# ============================================================================ #

# more environment variables defined next to the their corresponding aliases in aliases.sh

bash_tools="${bash_tools:-$(dirname "${BASH_SOURCE[0]}")/..}"

# shellcheck disable=SC1090,SC1091
. "$bash_tools/.bash.d/os_detection.sh"

# similar to what zsh does by default
if [ -f ~/.bashenv ]; then
    # shellcheck disable=SC1090,SC1091
    . ~/.bashenv
fi

#export DISPLAY=:0.0

#export TERM=xterm

export EDITOR=vim

export INPUTRC=~/.inputrc

# allow programs to use $LINES and $COLUMNS
export LINES
export COLUMNS

# sets directories to cyan on default bg so they stand out more in dark terminal - see 'man ls' for more details
# works on Mac - you may need to see 'man 5 dir_colors' on Linux
export LSCOLORS="gx"

# ENV refers to the file that sh attempts to read as a startup file (done on my Mac OSX Snow Leopard)
# Needs the following line added to sudoers for ENV to be passed through on sudo su
#Defaults	env_keep += "ENV"
export ENV=~/.bashrc

# ============================================================================ #

cpenv(){
    local env_var="$1"
    if [[ -z "${!env_var}" ]]; then
        echo "Error: Environment variable '$env_var' is not set"
        return 1
    fi
    copy_to_clipboard.sh <<< "${!env_var}"
    echo "Value of '$env_var' has been copied to the clipboard"
}

# Autocomplete function for environment variables
_cpenv_autocomplete() {
    # 'compgen -v' lists all environment variables
    # COMPREPLY is set to the autocomplete options
    local cur_word="${COMP_WORDS[COMP_CWORD]}"
    COMPREPLY=($(compgen -v -- "$cur_word"))
}

# Register autocomplete function for `cpenv`
complete -F _cpenv_autocomplete cpenv


# ============================================================================ #
#             L o c a l e   I n t e r n a t i o n a l i z a t i o n
# ============================================================================ #

# Run this to see available locales:
#
#   locale -a
#
# See details of a specific locale variable eg. time formats:
#
#   LC_ALL=C locale -ck LC_TIME

# aterm doesn't support UTF-8 and you get horrible chars here and there
# so don't use utf and aterm together. xterm works ok with utf8 though
#export LANG=en_GB
#
# LANG becomes default value for any LC_xxx variables not set
#export LANG=C
#
# overrides all other LC_xxx variables
#export LC_ALL=C
#
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
#export LC_ALL=en_GB
# didn't seem to work
#export LANG="en_GB.UTF-8"
#export LC_ALL="en_GB.UTF-8"

# ============================================================================ #

# Clever dynamic environment variables, set using var() function sourced between shells
export varfile=~/.bash_vars
# shellcheck disable=SC1090,SC1091
[ -f "$varfile" ] && . "$varfile"

# Secret Credentials
#
#   separate cred files so if you accidentally expose it on a screen
#   to colleagues or on a presentation or screen share
#   you don't have to change all of your passwords
#   which you would have to if using the above ~/.bash_vars file
if [ -d ~/.env/creds ]; then
    for credfile in ~/.env/creds/*; do
        if [ -f "$credfile" ]; then
            # shellcheck disable=SC1090,SC1091
            . "$credfile"
        fi
    done
fi

#export DISTCC_DIR="/var/tmp/portage/.distcc/"

# ============================================================================ #

if is_mac; then
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
if ! is_mac; then
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
    # shellcheck disable=SC1090,SC1091
    . "$varfile"
}

unvar(){
    local var="${*%%=*}"
    [ -f "$varfile" ] || { echo "$varfile not found" ; return 1; }
    perl -pi -e 's/^export '"$var"'=.*\n$//' "$varfile"
    unset "$var"
}

# ============================================================================ #

unsetall(){
    local match="${1:-.*}"
    while read -r env_var; do
        if [ "$env_var" = PATH ]; then
            continue
        fi
        unset "$env_var"
    done < <( env |
        grep -i "$match" |
        sed 's/=.*//' )
}
