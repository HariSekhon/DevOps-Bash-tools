#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: circa 2009+ (forked from .bashrc)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# ============================================================================ #
#                        H a d o o p   E c o s y s t e m
# ============================================================================ #

#srcdir="${srcdir:-$(dirname "${BASH_SOURCE[0]}")/..}"

# shellcheck disable=SC1090,SC1091
#type add_PATH &>/dev/null || . "$srcdir/.bash.d/paths.sh"

# ============================================================================ #
#                                    E n v s
# ============================================================================ #

## ln -s -- /usr/local/hadoop-x.y.z /usr/local/hadoop
## ln -s -- /usr/local/hbase-x.y.z /usr/local/hadoop
## ln -s -- /usr/local/zookeeper-x.y.z /usr/local/zookeeper
#
# #find /usr/local -type d -name 'hadoop-*' -o -type d -name 'hbase-*' -o -type d -name 'zookeeper-*' -maxdepth 1 | while read path; do sudo ln -vfsh "$path" "${path%%-*}"; done
# link_latest '/usr/local/hadoop-*' '/usr/local/hbase-*' '/usr/local/pig-*' '/usr/local/zookeeper-*'
# chown -R hari -- /usr/local/{hadoop,hbase,zookeeper}
# re-enabled HADOOP_HOME for Kite SDK

#export HADOOP_HOME="/usr/local/hadoop"    # Deprecated. Annoying error msgs
#export HADOOP_PREFIX="/usr/local/hadoop"  # Hate this
## For OSX
#export HADOOP_OPTS="$HADOOP_OPTS -Djava.security.krb5.realm= -Djava.security.krb5.kdc="
#export HBASE_OPTS="  $HBASE_OPTS -Djava.security.krb5.realm= -Djava.security.krb5.kdc="
#export HBASE_HOME=/usr/local/hbase
#export PIG_HOME=/usr/local/pig
#export ZOOKEEPER_HOME=/usr/local/zookeeper
#add_PATH "$HADOOP_PREFIX/bin"
#add_PATH "$HBASE_HOME/bin"
#add_PATH "$PIG_HOME/bin"
#add_PATH "$ZOOKEEPER_HOME/bin"

#export MAHOUT_HOME=/usr/local/mahout
## indicates to run locally instead of on Hadoop
#export MAHOUT_LOCAL=true
#add_PATH "$MAHOUT_HOME/bin"

# ============================================================================ #
#                                     C L I
# ============================================================================ #

# Hadoop CLI usability is weak so some conveniences for day to day

alias dfs='hdfs dfs'
alias dfsls='hdfs dfs -ls'

alias yarnapp='yarn application'

alias impala='impala_shell.sh'

# nobody should use hive 1 cli any more, remap it to HS2 beeline
alias hive='beeline.sh'
alias hivezk='beeline_zk.sh'
