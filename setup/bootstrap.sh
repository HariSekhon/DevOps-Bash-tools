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

# Alpine / Wget:
#
# wget https://raw.githubusercontent.com/HariSekhon/DevOps-Bash-tools/master/setup/bootstrap.sh && sh bootstrap.sh
#
# Curl:
#
# curl https://raw.githubusercontent.com/HariSekhon/DevOps-Bash-tools/master/setup/bootstrap.sh | sh

set -eu
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

repo="https://github.com/HariSekhon/DevOps-Bash-tools"

directory="bash-tools"

if [ "$(uname -s)" = Darwin ]; then
    echo "Bootstrapping Mac"
    curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install | ruby
elif [ "$(uname -s)" = Linux ]; then
    echo "Bootstrapping Linux"
    if type apk >/dev/null 2>&1; then
        apk --no-cache add bash git make
    elif type apt-get >/dev/null 2>&1; then
        apt-get update
        apt-get install -y git make
    elif type yum >/dev/null 2>&1; then
        yum install -y git make
    else
        echo "Package Manager not found on Linux, cannot bootstrap"
        exit 1
    fi
else
    echo "Only Mac & Linux are supported for conveniently bootstrapping all install scripts at this time"
    exit 1
fi

if [ "${srcdir##*/}" = setup ]; then
    cd "$srcdir/.."
elif [ -d "$directory" ]; then
    cd pytools
else
    git clone "$repo" "$directory"
    cd "$directory"
fi

make
