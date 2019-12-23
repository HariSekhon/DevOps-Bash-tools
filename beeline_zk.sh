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

# Script to more easily connect to HiveServer2 without having to specify the big connection string or look up the ZooKeepers

# see more documentation in the header of the adjacent beeline.sh script

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

hive_site_xml=/etc/hive/conf/hive-site.xml

# xq -r < hive-site.xml '.configuration.property[] | select(.name == "hive.zookeeper.quorum") | .value'
if [ -z "${ZOOKEEPERS:-}" ]; then
    ZOOKEEPERS="$(grep -A1 hive.zookeeper.quorum "$hive_site_xml" 2>/dev/null | grep '<value>' | sed 's/<value>//;s,</value>,,;s/[[:space:]]*//g')"
    if [ -z "${ZOOKEEPERS:-}" ]; then
        echo "ZOOKEEPERS environment variable not set (format is zookeeper1.domain.com:2181,zookeeper2.domain.com:2181,zookeeper3.domain.com:2181)"
        exit 3
    fi
fi

# xq -r < hive-site.xml '.configuration.property[] | select(.name == "hive.zookeeper.namespace") | .value'
if [ -z "${HIVESERVER2_ZOOKEEPER_NAMESPACE:-}" ]; then
    HIVESERVER2_ZOOKEEPER_NAMESPACE="$(grep -A1 hive.zookeeper.namespace "$hive_site_xml" 2>/dev/null | grep '<value>' | sed 's/<value>//;s,</value>,,; s/hive_zookeeper_namespace_//; s/[[:space:]]*//g')"
    #HIVESERVER2_ZOOKEEPER_NAMESPACE="${HIVESERVER2_ZOOKEEPER_NAMESPACE:-hive}"
    HIVESERVER2_ZOOKEEPER_NAMESPACE="${HIVESERVER2_ZOOKEEPER_NAMESPACE:-hiveserver2}"
fi

opts=""
if [ -n "${BEELINE_OPTS:-}" ]; then
    opts="$opts;$BEELINE_OPTS"
fi

# xq -r < hive-site.xml '.configuration.property[] | select(.name == "hive.server2.use.SSL") | .value'
if [ -n "${HIVESERVER2_SSL:-}" ] ||
   grep -A1 'hive.server2.use.SSL' /etc/hive/conf/hive-site.xml 2>/dev/null |
   grep -q true; then
    opts="$opts;ssl=true"
    # works without this but enable if you need
    #set +o pipefail
    #trust_file="$(find /opt/cloudera/security/jks -maxdepth 1 -name '*-trust.jks' 2>/dev/null | head -n1)"
    #set -o pipefail
    #if [ -f "$trust_file" ]; then
    #    opts="$opts;sslTrustStore=$trust_file"
    #fi
fi

beeline -u "jdbc:hive2://$ZOOKEEPERS/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=${HIVESERVER2_ZOOKEEPER_NAMESPACE}${opts}" "$@"
