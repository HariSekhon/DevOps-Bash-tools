#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-07-28 14:46:37 +0100 (Sun, 28 Jul 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# ============================================================================ #
#                                   K a f k a
# ============================================================================ #

export PATH="$PATH:/usr/hdp/current/kafka-broker/bin"

kafka_wrappers="$(dirname "${BASH_SOURCE[0]}")/../kafka_wrappers"
export PATH="$PATH:$kafka_wrappers"

# HDP defaults to 8GB, on VMs that often breaks cli commands which try to claim too much ram and fail
export KAFKA_OPTS="$KAFKA_OPTS -Xms1G -Xmx1G"

# there was another setting like KAFKA_KERBEROS_CLIENT I've used before but can't remember, this should work too
kafka_cli_jaas_conf="$(dirname "${BASH_SOURCE[0]}")/../kafka_wrappers/kafka_cli_jaas.conf"
export KAFKA_OPTS="$KAFKA_OPTS -Djava.security.auth.login.config=$kafka_cli_jaas_conf"

# ============================================================================ #

# XXX: Enable KAFKA_BROKERS and KAFKA_ZOOKEEPER for convenience
#      of not having to specify them each time when using kafka_wrapper/ commands

# XXX: Must use FQDNs to match Kerberos service principals

# Apache / Cloudera
#export KAFKA_BROKERS="$(hostname -f):9092"

# Hortonworks
#export KAFKA_BROKERS="$(hostname -f):6667"

#export KAFKA_ZOOKEEPERS="$(hostname -f):2181"

# optional - use if chrooting in zookeeper
#export KAFKA_ZOOKEEPER_ROOT=/kafka

# ============================================================================ #

bootstrap_server=""
echo "$*"
if [ -n "${KAFKA_BROKERS:-}" ] &&
   ! [[ "$*" =~ --bootstrap-server ]]; then
    # shellcheck disable=SC2034
    bootstrap_server="--bootstrap-server $KAFKA_BROKERS"
fi

broker_list=""
if [ -n "${KAFKA_BROKERS:-}" ] &&
   ! [[ "$*" =~ --broker-list ]]; then
    # shellcheck disable=SC2034
    broker_list="--broker-list $KAFKA_BROKERS"
fi

kafka_zookeeper=""
if [ -n "${KAFKA_ZOOKEEPERS:-}" ] &&
   ! [[ "$*" =~ --zookeeper ]]; then
    # shellcheck disable=SC2034
    kafka_zookeeper="--zookeeper $KAFKA_ZOOKEEPERS"
fi
