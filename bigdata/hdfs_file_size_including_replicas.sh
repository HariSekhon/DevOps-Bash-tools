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
Recurses HDFS path arguments outputting:

<disk_space_for_all_replicas>     <filename>

Calls HDFS command which is assumed to be in \$PATH

Make sure to kinit before running this if using a production Kerberized cluster


usage: ${0##*/} <file_or_directory_paths> [hdfs_dfs_du_options]


EOF
    exit 3
}

for arg; do
    case "$arg" in
        # not including -h here because du -h is needed for human readable format
        --help) usage
                ;;
    esac
done

# if using -h there will be more columns so remove cols 1 + 2 and use cols 3 + 4 for sizes including replicas eg.
#
# 21.7 M  65.0 M  hdfs://nameservice1/user/hive/warehouse/...
#
# otherwise will be in format
#
# 22713480  68140440  hdfs://nameservice1/user/hive/warehouse/...

hdfs dfs -du "$@" |
awk '{ if($2 ~ /[A-Za-z]/){ $1=""; $2="" } else { $2=""  }; print  }' |
column -t
