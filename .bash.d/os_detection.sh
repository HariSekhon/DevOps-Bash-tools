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

[ -n "$OS_DETECTION_RUN" ] && return

uname="$(uname)"

if [ "$uname" = Linux ]; then
	export LINUX=1
elif [ "$uname" = Darwin ]; then
	export APPLE=1
	export OSX=1
fi

export OS_DETECTION_RUN=1
