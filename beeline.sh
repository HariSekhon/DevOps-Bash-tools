#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-12-06 11:10:26 +0000 (Fri, 06 Dec 2019)
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

if [ -z "${HIVESERVER2_HOST:-}" ]; then
    echo "HIVESERVER2_HOST environment variable not set"
    exit 3
fi

ssl=""
if [ -n "${HIVESERVER2_SSL:-}" ] ||
   grep -A1 'hive.server2.use.SSL' /etc/hive/conf/hive-site.xml 2>/dev/null | grep -q true; then
    ssl=";ssl=true"
fi

beeline -u "jdbc:hive2://$HIVESERVER2_HOST:10000/default;principal=hive/$HIVESERVER2_HOST@${HIVESERVER2_HOST#*.}$ssl"
