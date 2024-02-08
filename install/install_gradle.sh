#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2016-08-01 10:17:55 +0100 (Mon, 01 Aug 2016)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

echo "================================================================================"
echo "                           G r a d l e   I n s t a l l"
echo "================================================================================"

GRADLE_VERSION=${1:-${GRADLE_VERSION:-7.3.3}}

am_root(){
    [ "${EUID:-${UID:-$(id -n)}}" = 0 ]
}
if am_root; then
    BASE=/opt
else
    BASE=~/bin
fi

echo
date '+%F %T  Starting...'
start_time="$(date +%s)"
echo

if [ -e "$BASE/gradle" ]; then
    echo "$BASE/gradle already exists, skipping download"
else
    mkdir -pv "$BASE"
    cd "$BASE"
    wget -c -t 10 --retry-connrefused "https://services.gradle.org/distributions/gradle-$GRADLE_VERSION-bin.zip"
    unzip "gradle-$GRADLE_VERSION-bin.zip"
    rm -f -- "gradle-$GRADLE_VERSION-bin.zip"
    echo
    echo "Gradle Install done"
fi
if am_root; then
    ln -sv -- "gradle-$GRADLE_VERSION" gradle
    if ! [ -e /etc/profile.d/gradle.sh ]; then
        echo "Adding /etc/profile.d/gradle.sh"
        # shell execution tracing comes out in the file otherwise
        set +x
        cat >> /etc/profile.d/gradle.sh <<EOF
export GRADLE_HOME=/opt/gradle
export PATH=\$PATH:\$GRADLE_HOME/bin
EOF
    fi
else
    ln -fsv -- ~/bin/"gradle-$GRADLE_VERSION"/bin/gradle ~/bin
    echo "Ensure you have ~/bin set in your \$PATH"
fi

echo
date '+%F %T  Finished'
echo
end_time="$(date +%s)"
time_taken="$((end_time - start_time))"
echo "Completed in $time_taken secs"
echo
echo "=================================================="
echo "            Gradle Install Completed"
echo "=================================================="
echo
