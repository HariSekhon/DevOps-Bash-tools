#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2016-08-01 10:17:55 +0100 (Mon, 01 Aug 2016)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

echo "================================================================================"
echo "                              S B T   I n s t a l l"
echo "================================================================================"

SBT_VERSION=${1:-${SBT_VERSION:-0.13.12}}

BASE=/opt

echo
date '+%F %T  Starting...'
start_time="$(date +%s)"
echo

if ! [ -e "$BASE/sbt" ]; then
    mkdir -p "$BASE"
    cd "$BASE"
    wget -t 100 --retry-connrefused https://dl.bintray.com/sbt/native-packages/sbt/$SBT_VERSION/sbt-$SBT_VERSION.tgz && \
    tar zxvf sbt-$SBT_VERSION.tgz && \
    rm -f sbt-$SBT_VERSION.tgz
    echo
    echo "SBT Install done"
else
    echo "$BASE/sbt already exists - doing nothing"
fi
if ! [ -e /etc/profile.d/sbt.sh ]; then
    echo "Adding /etc/profile.d/sbt.sh"
    # shell execution tracing comes out in the file otherwise
    set +x
    cat >> /etc/profile.d/sbt.sh <<EOF
export SBT_HOME=/opt/sbt
export PATH=\$PATH:\$SBT_HOME/bin
EOF
fi

echo
date '+%F %T  Finished'
echo
end_time="$(date +%s)"
# if start and end time are the same let returns exit code 1
let time_taken=$end_time-$start_time || :
echo "Completed in $time_taken secs"
echo
echo "=================================================="
echo "              SBT Install Completed"
echo "=================================================="
echo
