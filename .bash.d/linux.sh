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

bash_tools="${bash_tools:-$(dirname "${BASH_SOURCE[0]}")/..}"

# shellcheck disable=SC1090
. "$bash_tools/.bash.d/os_detection.sh"

isLinux || return

alias reloadXdefaults="xrdb ~/.Xdefaults"

#setxkbmap us

# Assign middle mouse to my Alt Gr key
# TODO:  change this to keysym as keycodes can change between keyboards, to find keymaps do
# xmodmap -pkie

if [ -n "$DISPLAY" ] && ! isMac; then
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

# ==========================
# When using Samba WinPopups on Linux in Windows workgroups - convenient back in the day but shouldn't be needed today with the plethora of better chat tools
#
#netsend(){ smbclient -M "$1" <<< "${*:2}"; }
#alias ns=netsend
#
# clear pop-ups and alerts if sending instant security alerts
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
# =========================
