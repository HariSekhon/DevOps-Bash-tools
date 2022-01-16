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
# wget -O- https://raw.githubusercontent.com/HariSekhon/DevOps-Bash-tools/master/setup/bootstrap.sh | sh
#
# Curl:
#
# curl https://raw.githubusercontent.com/HariSekhon/DevOps-Bash-tools/master/setup/bootstrap.sh | sh

set -eux

repo="$(env | grep ^PATH= | sed 's/.*github\///; s/:.*//')"

github="/github"

mkdir -pv "$github"

cd "$github"

if type -P apt-get >/dev/null 2>&1; then
    apt-get update
    apt-get install -y curl
elif type -P apk >/dev/null 2>&1; then
    apk add --no-cache curl
fi

curl -sS "https://raw.githubusercontent.com/HariSekhon/$repo/master/setup/bootstrap.sh" | sh

if [ "$repo" = python-tools ]; then
    ln -sv python-tools pytools
fi

cd "$github/$repo"

make test

curl -sS https://raw.githubusercontent.com/HariSekhon/DevOps-Bash-tools/master/clean_caches.sh | sh
