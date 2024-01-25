#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-07-30 15:16:58 +0100 (Tue, 30 Jul 2019)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -u
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# sources heap, kerberos, brokers, zookeepers etc
# shellcheck source=.bash.d/kafka.sh
. "$srcdir/.bash.d/kafka.sh"

# it's assigned in .bash.d/kafka.sh
# shellcheck disable=SC2154,SC2086
kafka-configs.sh $kafka_zookeeper "$@"
