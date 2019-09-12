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
echo "                           G r o o v y   I n s t a l l"
echo "================================================================================"

GROOVY_VERSION=${1:-${GROOVY_VERSION:-2.4.7}}

BASE=/opt

date '+%F %T  Starting...'
start_time="$(date +%s)"
echo

if ! [ -e "$BASE/groovy" ]; then
    mkdir -p "$BASE"
    cd "$BASE"
    wget -t 100 --retry-connrefused "https://dl.bintray.com/groovy/maven/apache-groovy-binary-$GROOVY_VERSION.zip" && \
    unzip "apache-groovy-binary-$GROOVY_VERSION.zip" && \
    ln -sv "groovy-$GROOVY_VERSION" groovy && \
    rm -f "apache-groovy-binary-$GROOVY_VERSION.zip"
    echo
    echo "Groovy Install done"
else
    echo "$BASE/groovy already exists - doing nothing"
fi
if ! [ -e /etc/profile.d/groovy.sh ]; then
    echo "Adding /etc/profile.d/groovy.sh"
    # shell execution tracing comes out in the file otherwise
    set +x
    cat >> /etc/profile.d/groovy.sh <<EOF
export GROOVY_HOME=/opt/groovy
export PATH=\$PATH:\$GROOVY_HOME/bin
EOF
fi

echo
date '+%F %T  Finished'
echo
end_time="$(date +%s)"
time_taken="$((end_time - start_time))"
echo "Completed in $time_taken secs"
echo
echo "=================================================="
echo "            Groovy Install Completed"
echo "=================================================="
echo
