#!/bin/sh
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

set -eu
[ -n "${DEBUG:-}" ] && set -x

echo "================================================================================"
echo "                              S B T   I n s t a l l"
echo "================================================================================"

SBT_VERSION=${1:-${SBT_VERSION:-1.6.1}}

am_root(){
    # shellcheck disable=SC2039
    [ "${EUID:-${UID:-$(id -n)}}" = 0 ]
}
if am_root; then
    BASE=/opt
    sudo=""
else
    BASE=~/bin
    sudo=sudo
fi

echo
date '+%F %T  Starting...'
start_time="$(date +%s)"
echo

if command -v yum 2>/dev/null; then
    curl -sSL https://www.scala-sbt.org/sbt-rpm.repo |
        $sudo tee /etc/yum.repos.d/sbt-rpm.repo
    $sudo yum install -y java-sdk
    $sudo yum install -y --nogpgcheck sbt
elif command -v apt-get 2>/dev/null; then
    $sudo apt-get update
    openjdk="$(apt-cache search openjdk | grep -Eo 'openjdk-[[:digit:]]+-jdk' | head -n1)"
    $sudo apt-get install -y "$openjdk" scala gnupg2
    echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" |
        $sudo tee /etc/apt/sources.list.d/sbt.list
    echo "deb https://repo.scala-sbt.org/scalasbt/debian /" |
        $sudo tee /etc/apt/sources.list.d/sbt_old.list
    $sudo apt-get install -y apt-transport-https curl gnupg
    curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" |
        ${sudo:+$sudo -H} gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/scalasbt-release.gpg --import
    $sudo chmod 644 /etc/apt/trusted.gpg.d/scalasbt-release.gpg
    $sudo apt-get update
    $sudo apt-get install -y sbt
else
    echo "No mainstream package managers detected, doing tarball install"
    if ! [ -e "$BASE/sbt" ]; then
        mkdir -p "$BASE"
        cd "$BASE"
        wget -t 10 --retry-connrefused "https://github.com/sbt/sbt/releases/download/v$SBT_VERSION/sbt-$SBT_VERSION.tgz" && \
        tar zxvf "sbt-$SBT_VERSION.tgz" && \
        rm -f -- "sbt-$SBT_VERSION.tgz"
        echo
        echo "SBT Install done"
    else
        echo "$BASE/sbt already exists - doing nothing"
    fi
    if am_root; then
        if ! [ -e /etc/profile.d/sbt.sh ]; then
            echo "Adding /etc/profile.d/sbt.sh"
            # shell execution tracing comes out in the file otherwise
            set +x
            cat >> /etc/profile.d/sbt.sh <<EOF
export SBT_HOME=/opt/sbt
export PATH=\$PATH:\$SBT_HOME/bin
EOF
        fi
    else
        echo "Ensure you have ~/bin/sbt/bin set in your \$PATH"
    fi
fi

echo
date '+%F %T  Finished'
echo
end_time="$(date +%s)"
time_taken="$((end_time - start_time))"
echo "Completed in $time_taken secs"
echo
echo "=================================================="
echo "              SBT Install Completed"
echo "=================================================="
echo
