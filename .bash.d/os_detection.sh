#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: circa 2010 - 2012 (forked from .bashrc)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

[ -n "${OS_DETECTION_RUN:-}" ] && return

get_os(){
    if [ -z "$operating_system" ] ||
       ! [[ "$operating_system" =~ ^(Linux|Darwin)$ ]]; then
        operating_system="$(uname -s)"
    fi
}

isLinux(){
    get_os
    [ "$operating_system" = Linux ]
}

isMac(){
    get_os
    [ "$operating_system" = Darwin ]
}

if isLinux; then
	export LINUX=1
    if [ -n "${DEVSHELL_PROJECT_ID:-}" ]; then
        export GOOGLE_CLOUD_SHELL=1
    fi
elif isMac; then
	export APPLE=1
	export OSX=1
fi

export OS_DETECTION_RUN=1
