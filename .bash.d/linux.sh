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

