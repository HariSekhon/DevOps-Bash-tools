#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-04-15 18:19:22 +0100 (Wed, 15 Apr 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Install OpenSSH - callable via curl to bash from builds
#
# Written for use in AppVeyor to install OpenSSH if not installed already to work around issues:
#
# https://github.com/appveyor/ci/issues/3373
#
# https://github.com/appveyor/ci/issues/3384
#
# has since been added to AppVeyor's own scripts:
#
# https://github.com/appveyor/ci/pull/3385

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

sudo=""
[ $EUID -eq 0 ] || sudo=sudo

if ! command -v sshd &>/dev/null; then
    if command -v apt-get &>/dev/null; then
        $sudo apt-get update
        $sudo apt-get install -y openssh-server
    elif command -v yum &>/dev/null; then
        $sudo yum install -y openssh-server
    elif command -v apk &>/dev/null; then
        $sudo apk update
        $sudo apk add openssh-server
    fi
fi
