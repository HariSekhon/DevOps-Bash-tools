#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-12-06 12:09:19 +0000 (Fri, 06 Dec 2019)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Script to more easily connect to ZooKeeper without having to look up the ZooKeeper addresses

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

if [ -z "${ZOOKEEPERS:-}" ]; then
    set +o pipefail
    ZOOKEEPERS="$(find /etc -name '*-site.xml' -exec grep -hA1 zookeeper.quorum {} \; 2>/dev/null | grep '<value>' | sed 's/<value>//;s,</value>,,;s/[[:space:]]*//g' | sort -u | head -n1)"
    set -o pipefail
    if [ -z "${ZOOKEEPERS:-}" ]; then
        echo "ZOOKEEPERS environment variable not set (format is zookeeper1.domain.com:2181,zookeeper2.domain.com:2181,zookeeper3.domain.com:2181)"
        exit 3
    fi
fi

exec zookeeper-client -server "$ZOOKEEPERS" "$@"
