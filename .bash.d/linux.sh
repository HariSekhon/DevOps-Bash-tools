#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2006 (forked from .bashrc)
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
#                                   L i n u x
# ============================================================================ #

# Linux specific bits to not include on Mac

# most of the regular stuff is in the other bash.d/*.sh files

[ -n "$APPLE" ] && return

alias reloadXdefaults="xrdb ~/.Xdefaults"

#setxkbmap us

# Assign middle mouse to my Alt Gr key
# TODO:  change this to keysym as keycodes can change between keyboards, to find keymaps do
# xmodmap -pkie

if [ -n "$DISPLAY" ] && [ -z "${APPLE:-}" ]; then
    # This caused the left to be remapped, must test and handle better
    #xmodmap -e 'keycode 113 = Pointer_Button2'
    #xmodmap -e 'keycode 113 = Left NoSymbol Left'
    xkbset m
    # Ubuntu 12.04.1 LTS had a bug where it turned off repeat keys on my down arrow, this fixed it
    xkbset repeatkeys 116
fi

rpmqf(){
    rpm -qf "$(readlink -m "$1")"
}

fixtime(){
    # $sudo defined in .bashrc
    # shellcheck disable=SC2154
    $sudo /etc/init.d/ntp stop
    $sudo ntpdate pool.ntp.org
    $sudo /etc/init.d/ntp start
}

getmounts(){
    #grep -e "ext" -e "reiser" -e "fat" -e "ntfs" < /proc/mounts |
    #awk '{ print $2 }'
    awk '/ext|reiser|fat|ntfs|btrfs|xfs/{print $2}'
}

findsuid(){ 
    for x in $(getmounts); do
        echo "Searching $x for suid programs:"
        # $sudo defined in .bashrc if not root
        # shellcheck disable=SC2154
        $sudo find "$x" -xdev -type f -perm -u+s -exec ls -l {} \;
    done
}

findguid(){
    for x in $(getmounts); do
        echo "Searching $x for guid programs:"
        $sudo find "$x" -xdev -type f -perm -g+s -exec ls -l {} \;
    done
}

findsguid(){
    for x in $(getmounts); do
        echo "Searching $x for suid and guid programs:"
        $sudo find "$x" -xdev -type f \( -perm -u+s -o -perm -g+s \) -exec ls -l {} \;
    done
}

findwritable(){
    for x in $(getmounts); do
        echo "Searching $x for world writeable files:"
        $sudo find "$x" -xdev -type f -perm -o+w -exec ls -l {} \;
    done
}

# When using Samba WinPopups on Linux in Windows workgroups - convenient but shouldn't be needed today with the plethora of chat tools
#clearnetsend(){
#    sudo pkill -f sambapopup
#}
#alias cns=clearnetsend
#
#clearxmessage(){
#    while pkill xmessage; do
#        sleep 0.1
#    done
#    while pkill gmessage; do
#        sleep 0.1
#    done
#}

rdp(){
    [ -n "$1" ] || return 1
    local resolution="800x600"
    if [ "$(xdpyinfo | awk '/dimensions/ {print $2}' | sed 's/x.*//')" -gt 1024 ]; then
        resolution="1024x768"
    fi
    if command -v krdc &>/dev/null; then
        krdc "rdp:/$WINDOWSDOMAIN\\$WINDOWSUSER@$*" &
        exit 0
    elif command -v rdesktop &>/dev/null; then
        rdesktop -u "$WINDOWSUSER" -d "$WINDOWSDOMAIN" "$@" -g "$resolution" &
        exit 0
    else
        echo  "Could not find krdc or rdesktop in path"
        return 1
    fi
}
