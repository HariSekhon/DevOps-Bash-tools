#!/bin/sh
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-05-16 16:59:11 +0100 (Sat, 16 May 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -u
[ -n "${DEBUG:-}" ] && set -x

echo "Python / Pip versions installed:"
echo

# executing in sh where type is not available
#type -P python
for x in python python2 python3 pip pip2 pip3; do
    cmdpath="$(command -v "$x" 2>/dev/null)"
    if [ -n "$cmdpath" ]; then
        printf "%s" "$cmdpath => "
        "$cmdpath" -V
    fi
done
echo
for x in python python2 python3 pip pip2 pip3; do
    cmdpath="$(command -v "$x" 2>/dev/null)"
    if [ -n "$cmdpath" ]; then
        ls -l "$cmdpath"
    fi
done
