#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-06 12:03:19 +0000 (Fri, 06 Mar 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Script to download all audit logs from Cloudera Navigator
#
# Uses adjacent cloudera_manager_audit.sh, see comments there for more details
#
# Tested on Cloudera Enterprise 5.10

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

trap 'echo ERROR >&2' exit

current_year="$(date +%Y)"

compress_cmd="bzip2 -9 -c"

# works on Mac but seq on Linux doesn't do reverse, outputs nothing
#for year in $(seq "$current_year" 2009); do
# On Mac tac requires gnu coreutils to be installed via Homebrew
for year in $(seq 2009 "$current_year" | tac); do
    for service in hive impala hdfs hbase scm; do
        log="navigator_audit_${service}_${year}.csv"
        echo "Querying Cloudera Navigator for $year logs for $service"
        time "$srcdir/cloudera_navigator_audit.sh" "$year-01-01T00:00:00" "$((year+1))-01-01T00:00:00" "service==$service" "$@" | "$srcdir/progress_dots.sh" > "$log"
        compressed_log="$log.bz2"
        echo "Compressing audit log:  $log > $compressed_log"
        # want splitting
        # shellcheck disable=SC2086
        $compress_cmd "$log" > "$compressed_log" &
    done
done
echo "Finished querying Cloudera Navigator API"
echo "Waiting for log compression to finish"
wait
echo "DONE"
trap - exit
