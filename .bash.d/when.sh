#!/usr/bin/env bash
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
#                          W h e n   F u n c t i o n s
# ============================================================================ #

# interactive time latch alternative to 'at' command
when(){
    # should be in the format HH:MM:SS
    local time="$1"
    shift || :
    if ! grep -Eq "^[012]?[0-9]:[0-5]?[0-9]:[0-5]?[0-9]$" <<< "$time"; then
        echo "invalid time format - must be in format HH:MM:SS"
        return 1
    fi
    while true; do
        if [ "$(date '+%T')" = "$time" ]; then
            break
        fi
        sleep 1
    done
    "$@"
}

whenup(){
    local host="$1"
    shift || :
    checkhost "$host" || return 1
    local count=0
    # defined in network.sh
    # shellcheck disable=SC2154
    while ! ping -c 1 "$pingwait" 1 "$host" &>/dev/null; do
        ((count+=1))
        timestamp "waiting for $host to come up..."
        if [ $count -gt 22 ]; then
            sleep 10
        else
            sleep 5
        fi
    done
    timestamp "$host is up"
    "$@"
}

# HTTP(s) version of whenup because corporate firewalls block ping
whenurl(){
    local url="$1"
    shift || :
    local count=0
    while ! curl -s --connect-timeout 2 "$url" &>/dev/null; do
        ((count+=1))
        timestamp "waiting for $url to come up..."
        if [ $count -gt 22 ]; then
            sleep 10
        else
            sleep 5
        fi
    done
    timestamp "$url is up"
    "$@"
}

whendown(){
    local host="$1"
    shift || :
    checkhost "$host" || return 1
    local count=0
    while ping -c 1 "$pingwait" 1 "$host" &>/dev/null; do
        ((count+=1))
        timestamp "waiting for machine to go down..."
        if [ $count -gt 22 ]; then
            sleep 10
        else
            sleep 5
        fi
    done
    timestamp "machine is down"
    "$@"
}

whenport(){
    local host="$1"
    local port="$2"
    shift || :
    shift || :
    checkhost "$host" || return 1
    local count=0
    timestamp "checking port $port open..."
    checkprog nc
    while ! nc -z "${host#*@}" "$port" &>/dev/null; do
        ((count+=1))
        timestamp "waiting for port $port to open..."
        if [ $count -gt 22 ]; then
            sleep 10
        else
            sleep 5
        fi
    done
    timestamp "port $port is open"
    "$@"
}

whendone(){
    local search="$1"
    shift || :
    if [ -z "$search" ]; then
        echo "usage: when <search_for_prog_disappearing> <cmd>"
        return 1
    fi
    while true; do
        if ! pgrep -qf "$search"; then
            echo
            break
        else
            echo -n .
            sleep 1
        fi
    done
    "$@"
}
