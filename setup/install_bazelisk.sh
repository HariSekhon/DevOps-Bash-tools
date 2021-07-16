#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-07-16 18:53:36 +0100 (Fri, 16 Jul 2021)
#
#  https://github.com/HariSekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

BAZELISK_VERSION="${1:-1.10.1}"

export PATH="$PATH:$HOME/bin"

if type -P bazelisk &>/dev/null; then
    if bazelisk version | grep -q "^Bazelisk version: v$BAZELISK_VERSION$"; then
        echo "Bazelisk is already installed and the right version: $BAZELISK_VERSION"
        exit 0
    fi
fi

platform="$(uname -s | tr '[:upper:]' '[:lower:]')"

cd /tmp

wget -O bazelisk "https://github.com/bazelbuild/bazelisk/releases/download/v$BAZELISK_VERSION/bazelisk-$platform-amd64"

chmod +x bazelisk
mkdir -pv ~/bin
mv -v bazelisk ~/bin

bazelisk version
