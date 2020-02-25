#!/bin/sh
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-10-16 10:33:03 +0100 (Wed, 16 Oct 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -eu
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

if [ "$(uname -s)" = Darwin ]; then
    echo "Bootstrapping Mac"
    curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install | ruby
elif [ "$(uname -s)" = Linux ]; then
    echo "Bootstrapping Linux"
    if type apk 2>/dev/null; then
        apk --no-cache add bash git make
    elif type apt-get 2>/dev/null; then
        apt-get update
        apt-get install -y git make
    elif type yum 2>/dev/null; then
        yum install -y git make
    else
        echo "Package Manager not found on Linux, cannot bootstrap"
        exit 1
    fi
    if [ "${srcdir##*/}" = setup ]; then
        cd "$srcdir/.."
    elif [ -d "bash-tools" ]; then
        cd bash-tools
    else
        git clone https://github.com/HariSekhon/DevOps-Bash-tools bash-tools
        cd bash-tools
    fi
    make
else
    echo "Only Mac & Linux are supported for conveniently bootstrapping all install scripts at this time"
    exit 1
fi
