#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-02-17 11:11:52 +0000 (Sun, 17 Feb 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "${NO_FAIL:-}" ]; then
    set +eo pipefail
fi

if grep -qi "NAME=Fedora" /etc/*release; then
    echo "Detected Fedora, skipping epel install..."
    exit 0
fi

if rpm -q epel-release; then
    echo "EPEL rpm is already installed, skipping..."
    exit 0
fi

if ! yum repolist | grep -qi '\<epel\>'; then
    # accounts for custom internal EPEL mirrors which should have epel in the name
    echo "EPEL yum repo already detected in yum repolist, skipping..."
    exit 0
fi

if ! yum install -y epel-release; then
    rpm -q wget || yum install -y wget
    major_version="$(grep -o '[[:digit:]]' /etc/*release | head -n1)"
    wget -t 5 --retry-connrefused -O /tmp/epel.rpm "https://dl.fedoraproject.org/pub/epel/epel-release-latest-$major_release.noarch.rpm"
    $SUDO rpm -ivh /tmp/epel.rpm
    rm -f /tmp/epel.rpm;
fi
