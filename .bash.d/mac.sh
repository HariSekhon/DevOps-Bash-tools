#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: circa 2011 (forked from .bashrc)
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
#                           A p p l e   M a c   O S X
# ============================================================================ #

# More Mac specific stuff in adjacent *.sh files, especially network.sh

bash_tools="${bash_tools:-$(dirname "${BASH_SOURCE[0]}")/..}"

# shellcheck disable=SC1090,SC1091
. "$bash_tools/.bash.d/os_detection.sh"

is_mac || return

export HOMEBREW_DISPLAY_INSTALL_TIMES=1
#export HOMEBREW_DEBUG=1
#export HOMEBREW_CLEANUP_MAX_AGE_DAYS=30  # default: 120

# Stops Mac calling update_terminal_cwd() which causes a tonne of noise during set -x tracing
export INSIDE_EMACS=1

alias osash="osascript -i"
alias osashell=osash

if [ -x /opt/homebrew/bin/brew ]; then
    # shellcheck disable=SC2046
    eval $(/opt/homebrew/bin/brew shellenv)
fi

date(){
    gdate "$@"
}

xargs(){
    # because --no-run-if-empty is useful
    command gxargs "$@"
}

if ! type tac &>/dev/null; then
    tac(){
        gtac "$@"
    }
fi

# used for Shazaming while on headphones - see:
#
#   https://github.com/HariSekhon/Knowledge-Base/blob/master/audio.md#shazam-songs-while-using-headphones-on-mac
#
# Switches to Multi-Output Device which should already be configured as above and contain your headphones and BlackHole 2ch
#
#alias mshazam='SwitchAudioSource -s "Multi-Output Device"; open -a Shazam'
#alias msound='SwitchAudioSource -s "Multi-Output Device"'
unalias msound 2>/dev/null || :
msound(){
    # because if you have 2 multi-output devices eg.
    #
    # - one using AirPods + Blackhole
    # - another using Speakers + Blackhole
    #
    # then Mac automatically renames "Multi-Output Device" to "Multi-Output Device 1",
    # even if the other multi-output device has already been differentiated, it refuses to let you set
    # it back to the default name, so just determine what the first one is called and use that
    #
    local multi_output_device
    multi_output_device="$(SwitchAudioSource -a | grep -m1 '^Multi-Output Device')"
    #echo "Found first multi-output device: $multi_output_device"
    echo "Using first found multi-output device"
    SwitchAudioSource -s "$multi_output_device"
}


alias mshazam='msound; open -a Shazam'

vol(){
    if [ $# -ne 1 ]; then
        echo "usage: vol <num>"
        return 1
    fi
    osascript -e "set volume output volume $1"
}

# put in inputrc for readline
#set completion-ignore-case on

# Apple default in Terminal is xterm
#export TERM=xterm
# not sure why I set it to linux
#export TERM=linux
#ulimit -u 512

dhcprenew(){
    local interface="${1:-en0}"
    watch -q 1 ifconfig "$interface"
    sudo scutil <<< "add State:/Network/Interface/$interface/RefreshConfiguration temporary"
    watch ifconfig "$interface"
}

dhcpdiscover(){
    local interface="${1:-en0}"
    watch -q 1 ifconfig "$interface"
    sudo ipconfig set "$interface" BOOTP
    sudo ipconfig set "$interface" DHCP
    watch ifconfig "$interface"
}

macsleep(){
    sudo pmset sleepnow
}

nosleep(){
    echo "Running: caffeinate -s $*"
    echo "(works even if you close the Macbook lid but will still sleep on battery power)"
    caffeinate -s "$@"
}

silence_startup(){
    sudo nvram SystemAudioVolume=%80
}

top(){
    local opts=(-F -R -o)
    if [ $# -eq 1 ]; then
        command top "${opts[@]}" "$1"
    elif [ $# -gt 1 ]; then
        command top "$@"
    else
        command top "${opts[@]}" cpu
    fi
}

fixvbox(){
    sudo /Library/StartupItems/VirtualBox/VirtualBox restart
}

fixaudio(){
    sudo kextunload /System/Library/Extensions/AppleHDA.kext
    sudo kextload   /System/Library/Extensions/AppleHDA.kext
}

showhiddenfiles(){
    defaults write com.apple.finder AppleShowAllFiles YES
    # must killall Finder after this
}

alias reloadprefs='killall -u $USER cfprefsd'
alias strace="dtruss -f"
alias vlc="/Applications/VLC.app/Contents/MacOS/VLC"


# clear paste buffer
clpb(){
    copy_to_clipboard.sh < /dev/null
}

macmac(){
    ifconfig |
    awk '
        /^en[[:digit:]]+:/{gsub(":", "", $1); printf "%s:\t", $1}
        /^[[:space:]]ether[[:space:]]/{print $2}
    ' |
    # filters to only the lines with prefixed interfaces from first match
    grep '\t'
}

duall(){
    # bash_tools defined in .bashrc
    # shellcheck disable=SC2154
    du -ax "$bash_tools" | sort -k1n | tail -n 2000
    sudo du -ax / | sort -k1n | tail -n 50
}
alias dua=duall
if type -P brew &>/dev/null; then
    brew_prefix="$(brew --prefix)"
    if [ -f "$brew_prefix/etc/bash_completion" ]; then
        # shellcheck disable=SC1090,SC1091
        . "$brew_prefix/etc/bash_completion"
    fi
fi

brewupdate(){
    if ! brew update; then
        echo "remove the following to brew update"
        brew update 2>&1 | tee /dev/stderr | grep '^[[:space:]]*Library/Formula/' |
        while read -r formula; do
            echo rm -fv -- "/usr/local/$formula"
        done
        return 1
    fi
}

brewinstall(){
    brewupdate &&
    sed 's/#.*// ; /^[[:space:]]*$/d' < ~/mac-list.txt |
    while read -r pkg; do
        brew install "$pkg" #||
            #{ echo "FAILED"; break; }
    done
}

brew_find_unlinked_bins(){
     for x in /usr/local/Cellar/*/*/bin/*; do
         if ! [ -f "/usr/local/bin/${x##*/}" ]; then
             echo "$x"
        fi
    done
}

# don't export BROWSER on Mac, trigger python bug:
# AttributeError: 'MacOSXOSAScript' object has no attribute 'basename'
# from python's webbrowser library
#export BROWSER="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
#export BROWSER="/Applications/Firefox.app/Contents/MacOS/firefox"

# MacPorts - using HomeBrew instead in recent years
#if [ -e "/sw/etc/bash_completion" ]; then
#    . /sw/etc/bash_completion
#fi

# seems Mac OS X has a native pkill now
#pkill(){
#    local args=""
#    local regex=""
#    local grep_args=""
#    while [ -n "$1" ]; do
#        case "$1" in
#            -i) grep_args="$grep_args -i"
#                shift
#                ;;
#            -*) args="$args $1"
#                shift
#                ;;
#             *) regex="$1"
#                shift
#                ;;
#        esac
#    done
#    # TODO: check this a few times and then remove the echo
#    local proclist=$(ps -e | awk '{printf $1 OFS;for(i=4;i<=NF;i++)printf $i OFS;print""}' | grep $grep_args "$regex")
#    if [ -n "$proclist" ]; then
#        echo "$proclist"
#        awk '{print $1}' <<< "$proclist" | xargs echo kill $args
#        read -r -p "Kill all these processes? [y/N] " answer
#        if [ "$answer" = "y" ]; then
#            awk '{print $1}' <<< "$proclist" | xargs kill $args
#        fi
#    fi
#}
