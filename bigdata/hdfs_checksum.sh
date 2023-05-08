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
Recurses HDFS path arguments outputting HDFS MD5-of-MD5 checksums for each file

Calls HDFS command which is assumed to be in \$PATH

Capture stdout > file.txt for comparisons

Make sure to kinit before running this if using a production Kerberized cluster

Setting environment variable SKIP_ZERO_BYTE_FILES to any value will skip files with zero bytes to save time since
they always return the same anyway:   MD5-of-0MD5-of-0CRC32   00000000000000000000000070bc8f4b72a86921468bf8e8441dce5

Caveats:

This is slow because the HDFS command startup is slow and is called once per file path so doesn't scale well
If you want to skip zero byte files, set environment variable \$SKIP_ZERO_BYTE_FILES

See Also:

hadoop_hdfs_files_native_checksums.jy

from the adjacent GitHub repo:

https://github.com/HariSekhon/DevOps-Python-tools

I would have written this version in Python but the Snakebite library doesn't support checksum extraction


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
awk '{ $1=$2=$3=$4=$5=$6=$7=""; print }' |
#sed 's/^[[:space:]]*//' |
while read -r filepath; do
    hdfs dfs -checksum "$filepath"
done
