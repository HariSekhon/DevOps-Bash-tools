#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2012-06-25 15:20:39
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
#                                 S p i n n e r
# ============================================================================ #

spinner(){
    local msg="$* "
    #local num=${2:-100}
    local num=1000
    #local delay=${3:-0.00001}
    local delay=0.00001
    spin='-\|/'
    #printf "${msg//?/ }"
    printf "%s" "$msg "
    for ((i=0; i < num; i++)); do
        sleep $delay
        # This way results in more flashing
        #printf "\r${msg}${spin:$((${i}%${#spin})):1}"
        # TODO: naughty allowing variables in printf format string but fiddly with msg var replaced backspace otherwise, clean up later...
        # shellcheck disable=SC2059
        printf "\\b${msg//?/\\b}${msg}${spin:$((i % ${#spin})):1}"
    done
    printf '\b '
    echo
    echo "done"
}
