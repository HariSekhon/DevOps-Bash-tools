#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-01-16 12:22:40 +0000 (Thu, 16 Jan 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Script to print a random Hadoop node by parsing the Hadoop topology map from /etc
#
# Tested on CDH 5.10
#
# See also:
#
#   find_active_*.py - https://github.com/HariSekhon/DevOps-Python-tools
#
#   HAProxy Configs for many Hadoop and other technologies - https://github.com/HariSekhon/HAProxy-configs
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

topology_map="${HADOOP_TOPOLOGY_MAP:-/etc/hadoop/conf/topology.map}"

if ! [ -f "$topology_map" ]; then
    echo "File not found: $topology_map. Did you run this on a Hadoop node?" >&2
    exit 1
fi

# returns datanodes in the topology map by omitting nodes with that are masters / namenodes / control nodes
awk -F'"' '/<node name="[A-Za-z]/{print $2}' "$topology_map" |
grep -Ev '^[^.]*(name|master|control)' |
shuf -n 1
