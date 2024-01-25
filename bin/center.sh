#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2016-01-23 00:02:17 +0000 (Sat, 23 Jan 2016)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback
#
#  https://www.linkedin.com/in/HariSekhon
#

# borrowed from here:
#
# http://codereview.stackexchange.com/questions/94449/text-centering-function-in-bash

# This is only for local use, there is a much better Python version in my DevOps Python Tools repo:
#
#  https://github.com/HariSekhon/DevOps-Python-tools

set -euo pipefail

textsize="${#1}"
# I want this to only match my hr() function, not 27" iMac 5K screens
#width=$(tput cols)
width="${2:-${WIDTH:-80}}"
span="$(((width + textsize) / 2))"
printf "%${span}s\\n" "${1:-NO_MESSAGE_GIVEN_TO_CENTER}"
