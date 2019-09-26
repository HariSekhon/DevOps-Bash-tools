#!/bin/sh
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-02-28 19:38:57 +0000 (Thu, 28 Feb 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Cleans a docker environment - useful for pulling in to Dockerfile builds

set -eu
[ -n "${DEBUG:-}" ] && set -x

if command -v yum >/dev/null 2>&1; then
    yum autoremove -y
    yum clean all
    rm -rf /var/cache/yum
elif command -v apt-get >/dev/null 2>&1; then
    apt-get autoremove -y
    apt-get clean
elif command -v apk >/dev/null 2>&1; then
    :
fi
