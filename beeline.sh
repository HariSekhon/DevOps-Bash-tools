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

# Script to more easily connect to HiveServer2 without having to specify the big connection string

# useful options for scripting:     --silent=true --outputformat=tsv2
#
# list all databases
#
#   ./beeline.sh --silent=true --outputformat=tsv2 -e 'show databases' | tail -n +2
#
# list all tables in all databases
#
#   ./beeline.sh --silent=true --outputformat=tsv2 -e 'show databases' | tail -n +2 | while read db; do ./beeline.sh --silent=true --outputformat=tsv2 -e "show tables from $db" | sed "s/^/$db./"; done
#
# # tsv is deprecated and single quotes results, tsv2 is recommended and cleaner

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

if [ -z "${HIVESERVER2_HOST:-}" ]; then
    echo "HIVESERVER2_HOST environment variable not set"
    exit 3
fi

ssl=""
if [ -n "${HIVESERVER2_SSL:-}" ] ||
   grep -A1 'hive.server2.use.SSL' /etc/hive/conf/hive-site.xml 2>/dev/null |
   grep -q true; then
    ssl=";ssl=true"
    # works without this but enable if you need
    #set +o pipefail
    #trust_file="$(find /opt/cloudera/security/jks -maxdepth 1 -name '*-trust.jks' 2>/dev/null | head -n1)"
    #set -o pipefail
    #if [ -f "$trust_file" ]; then
    #    ssl="$ssl;sslTrustStore=$trust_file"
    #fi
fi

realm="${HIVESERVER2_HOST#*.}"

beeline -u "jdbc:hive2://$HIVESERVER2_HOST:10000/default;principal=hive/_HOST@${realm}${ssl}" "$@"
