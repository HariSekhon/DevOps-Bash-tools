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

set -eu
[ -n "${DEBUG:-}" ] && set -x
srcdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

. "$srcdir/utils.sh"

section "Maven Install"

MAVEN_VERSION=${MAVEN_VERSION:-3.3.9}

BASE=/opt

date
start_time="$(date +%s)"
echo

if ! [ -e "$BASE/maven" ]; then
    mkdir -p "$BASE"
    cd "$BASE"
    wget -t 100 --retry-connrefused https://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz
    tar zxvf apache-maven-$MAVEN_VERSION-bin.tar.gz
    ln -sv "apache-maven-$MAVEN_VERSION" maven
    rm -f "apache-maven-$MAVEN_VERSION-bin.tar.gz"
    echo
    echo "Maven Install done"
else
    echo "$BASE/maven already exists - doing nothing"
fi
if ! [ -e /etc/profile.d/maven.sh ]; then
    echo "Adding /etc/profile.d/maven.sh"
    # shell execution tracing comes out in the file otherwise
    set +x
    cat >> /etc/profile.d/maven.sh <<EOF
export MAVEN_HOME=/opt/maven
export PATH=\$PATH:\$MAVEN_HOME/bin
EOF
fi

echo
date
echo
end_time="$(date +%s)"
# if start and end time are the same let returns exit code 1
let time_taken=$end_time-$start_time || :
echo "Completed in $time_taken secs"
echo
section2 "Maven Install Completed"
echo
echo
