#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: circa 2006-2012 (forked from .bashrc)
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
#                                 N e t w o r k
# ============================================================================ #

alias 4="ping 4.2.2.1"

# using alias p for 'kubectl get pods' now
#alias ping="ping -n"
#alias p=ping

pingwait="-w"
[ "${APPLE:-}" ] && pingwait="-W"

checkhost(){
    if [ -z "$1" ]; then
        echo "usage: checkhost hostname/ip"
        return 1
    fi
    if grep -qi "unknown host" <<< "$(ping -c 1 "$pingwait" 1 "$1" 2>&1)"; then
        echo "Unknown host"
        return 1
    fi
}

alias google="while true; do ping www.google.com && break; sleep 1 || break; done"
alias g=google
alias wg="watch_url.pl google.com"
get_gw(){
    local gw
    gw="$(netstat -rn | awk '/^default/ {print $2;exit}')"
    if [ -z "$gw" ]; then
        echo "Could not find gateway, no default route! " >&2
        return 1
    fi
    echo "$gw"
}

gw(){
    local gw
    gw="$(get_gw)"
    [ -n "$gw" ] || return 1
    ping "$gw"
}


z(){
    local gw
    gw="$(get_gw)"
    if [ -n "$gw" ]; then
        whenup "$gw" &&
        whenup 4.2.2.1 &&
        whenup www.google.com echo "INTERNET OK"
    else
        echo "Couldn't find gateway, cannot test upstream connectivity!"
        return 1
    fi
}
