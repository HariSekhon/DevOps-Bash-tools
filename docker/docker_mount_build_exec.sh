#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-02-15 13:14:53 +0000 (Fri, 15 Feb 2019)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -eu
[ -n "${DEBUG:-}" ] && set -x

if [ $# != 1 ]; then
    echo "usage: ${00#*/} <docker_image>"
    exit 3
fi

docker_image="$1"

script="bin/exec_interactive.sh"
if [ -x "bash-tools/$script" ]; then
    script="bash-tools/$script"
fi

# 'which' command is not available in some bare bones docker images like centos
# cannot set -u because it results in unbound variable error for $USER
# cannot set -e because it will exit before the exec to persist
docker run -ti --rm -v "$PWD:/code" "$docker_image" sh -x "/code/$script" '
    cd /code
    if type apt-get &>/dev/null; then
        export DEBIAN_FRONTEND=noninteractive
        apt-get update
        apt-get install -y git make
    elif type apk &>/dev/null; then
        apk add --no-cache git make
    elif type yum &>/dev/null; then
        yum install -y git make
    fi
    make build test
'
