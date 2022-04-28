#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-11-27 16:09:34 +0000 (Wed, 27 Nov 2019)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

usage(){
    cat <<EOF
Recurses HDFS path arguments checking for any files with less than replication factor 3 and resetting them
back to replication factor 3

These files cause alerts during single node downtime / maintenance due to missing blocks and
should really be set to replication factor 3

Calls HDFS command which is assumed to be in \$PATH

Make sure to kinit before running this if using a production Kerberized cluster

Setting environment variable SKIP_ZERO_BYTE_FILES to any value will not list files with zero bytes


See also:

hdfs_find_replication_factor_1.sh (adjacent)

and

hdfs_find_replication_factor_1.py in DevOps Python tools repo which can
also reset these found files back to replication factor 3 to fix the issue

https://github.com/HariSekhon/DevOps-Python-tools


usage: ${0##*/} <file_or_directory_paths>


EOF
    exit 3
}

if [[ "${1:-}" =~ ^- ]]; then
    usage
fi

skip_zero_byte_files(){
    if [ -n "${SKIP_ZERO_BYTE_FILES:-}" ]; then
        awk '{if($5 != 0) print }'
    else
        cat
    fi
}

hdfs dfs -ls -R "$@" |
grep -v '^d' |
skip_zero_byte_files |
awk '{ if ($2 < 3) { $1=$2=$3=$4=$5=$6=$7=""; print } }' |
sed 's/^[[:space:]]*//' |
xargs --no-run-if-empty hdfs dfs -setrep 3
