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

# Builds a git repo (taken from the first /github/<name> component in $PATH) inside a docker image at /github and then runs tests and cleans the caches to minimize the docker image size

# Alpine / Wget:
#
#   wget -O- https://raw.githubusercontent.com/HariSekhon/DevOps-Bash-tools/master/setup/docker_bootstrap.sh | sh
#
# Curl:
#
#   curl https://raw.githubusercontent.com/HariSekhon/DevOps-Bash-tools/master/setup/docker_bootstrap.sh | sh

set -eux

basedir="/github"

repo="$(echo "$PATH" | tr ':' '\n' | grep "^$basedir/" | sed 's|/github/||' | head -n1)"

mkdir -pv "$basedir"

cd "$basedir"

if type -P apt-get >/dev/null 2>&1; then
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y curl
elif type -P yum >/dev/null 2>&1; then
    yum install -y curl
elif type -P apk >/dev/null 2>&1; then
    apk add --no-cache curl
fi

curl -sSf "https://raw.githubusercontent.com/HariSekhon/$repo/master/setup/bootstrap.sh" | sh

if [ "$repo" = pytools ]; then
    ln -sv python-tools "$basedir/pytools"
fi

cd "$basedir/$repo"

make test

curl -sSf https://raw.githubusercontent.com/HariSekhon/DevOps-Bash-tools/master/clean_caches.sh | sh
