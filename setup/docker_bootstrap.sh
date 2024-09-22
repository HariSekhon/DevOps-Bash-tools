#!/bin/sh
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-10-16 10:33:03 +0100 (Wed, 16 Oct 2019)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
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
if [ -n "${SHELL:-}" ] && [ "${SHELL##*/}" = "bash" ]; then
    set -o pipefail
fi

basedir="/github"

repo="$(echo "$PATH" | tr ':' '\n' | grep "^$basedir/" | sed 's|/github/||' | head -n1)"

if [ -z "$repo" ]; then
    echo "ERROR: could not determine repo from \$PATH components, no /github/<name> was found in \$PATH: $PATH"
    exit 1
fi

mkdir -pv "$basedir"

cd "$basedir"

# type -P doesn't work in bourne shell
if ! command -v curl >/dev/null 2>&1; then
    if command -v apt-get >/dev/null 2>&1; then
        export DEBIAN_FRONTEND=noninteractive
        apt-get update
        apt-get install -y curl  # --no-install-recommends  # will omit ca-certificates which will break the ability to curl the bootstrap script further down
    elif command -v yum >/dev/null 2>&1; then
        yum install -y curl
    elif command -v apk >/dev/null 2>&1; then
        apk add --no-cache curl
    fi
fi

# bourne shell won't detect subshell failure, so better to break this to detectable parts
#curl -sSf "https://raw.githubusercontent.com/HariSekhon/$repo/master/setup/bootstrap.sh" | sh

trap 'command rm -fv -- /bootstrap.sh /clean_caches.sh' INT QUIT TRAP ABRT TERM EXIT

curl -sSf "https://raw.githubusercontent.com/HariSekhon/$repo/master/setup/bootstrap.sh" > /bootstrap.sh

sh /bootstrap.sh

cd "$basedir/$repo"

if [ -z "${NO_TESTS:-}" ]; then
    make test
fi

curl -sSf https://raw.githubusercontent.com/HariSekhon/DevOps-Bash-tools/master/bin/clean_caches.sh > /clean_caches.sh

sh /clean_caches.sh
