#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-11-27 16:09:34 +0000 (Wed, 27 Nov 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback
#
#  https://www.linkedin.com/in/harisekhon
#

# Recurses HDFS path arguments outputting:
#
# <file_length>     <filename>
#
# Calls HDFS command which is assumed to be in $PATH
#
# Capture stdout > file.txt for comparisons
#
# Make sure to kinit before running this if using a production Kerberized cluster

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

hdfs dfs -ls -R "$@" |
grep -v '^d' |
awk '{$1=$2=$3=$4=$6=$7="";print}' |
#sed 's/^[[:space:]]*//'
column -t
