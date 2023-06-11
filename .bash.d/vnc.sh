#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: circa 2006 - 2012 (forked from .bashrc)
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
#                                     V N C
# ============================================================================ #

#bash_tools="${bash_tools:-$(dirname "${BASH_SOURCE[0]}")/..}"

# shellcheck disable=SC1090,SC1091
#. "$bash_tools/.bash.d/os_detection.sh"

if [ -d "/Applications/VNC Viewer.app/Contents/MacOS" ]; then
    export PATH+=":/Applications/VNC Viewer.app/Contents/MacOS"
fi

vncwho() {
    netstat -tW |
    grep ".*:5900 .*:.*" |
    awk '{a=$5; split(a,b,":"); print b[1]}'
}

vnc(){
    local host_port="$1"
    # if just a port number is given, then it's shorthand for localhost:<port_number> eg. for copying and pasting Qemu's randomly generated VNC port
    if [[ "$host_port" =~ ^[[:digit:]]+$ ]]; then
        host_port="localhost:$1"
    fi
    if test -x "/Applications/VNC Viewer.app/Contents/MacOS/vncviewer"; then
        "/Applications/VNC Viewer.app/Contents/MacOS/vncviewer" "$host_port" &
    elif type -P krdc &>/dev/null; then
        krdc "vnc:/$host_port" &
    elif type -P vncviewer &>/dev/null; then
        vncviewer "$host_port" &
    else
        echo "could not find krdc or vncviewer in \$PATH"
        return 1
    fi
}

revnc(){
    local host_port="$1"
    local host="$host_port"
    if [[ "$host" =~ : ]]; then
        host="${host%%:*}"
    fi
    if [ -z "$1" ]; then
        echo "You must supply a hostname or ip address to connect to"
        return 1
    fi
    # $pingwait is defined in network.sh
    # shellcheck disable=SC2154
    while ! ping -c 1 "$pingwait" 1 "$host" &>/dev/null; do
        sleep 1
    done
    timestamp "machine is up"
    until vnc "$host_port"; do
        sleep 1
        timestamp "retrying $host_port"
    done
}
