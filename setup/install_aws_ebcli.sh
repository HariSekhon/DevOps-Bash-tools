#!/usr/bin/env bash
# vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-05-17 16:02:53 +0100 (Tue, 17 May 2022)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying LICENSE file
#
#  https://www.linkedin.com/in/HariSekhon
#

# Installs Elastic Beanstalk CLI
#
# https://github.com/aws/aws-elastic-beanstalk-cli-setup

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/../lib/utils.sh"

# shellcheck disable=SC1090,SC1091
. "$srcdir/../lib/ci.sh"

section "Install Elastic Beanstalk CLI"

mkdir -pv ~/github

cd ~/github

if [ -d aws-elastic-beanstalk-cli-setup ]; then
    pushd  aws-elastic-beanstalk-cli-setup
    git pull
    popd
else
    git clone https://github.com/aws/aws-elastic-beanstalk-cli-setup.git
fi

python3="$(type -P python3)"

if is_linux; then
    if type -P apt-get; then
        apt-get install -y \
            build-essential \
            zlib1g-dev \
            libssl-dev \
            libncurses-dev \
            libffi-dev \
            libsqlite3-dev \
            libreadline-dev \
            libbz2-dev
    elif type -P yum; then
        yum group install -y "Development Tools"
        yum install -y \
            zlib-devel \
            openssl-devel \
            ncurses-devel \
            libffi-devel \
            sqlite-devel.x86_64 \
            readline-devel.x86_64 \
            bzip2-devel.x86_64
    fi
elif is_mac; then
    brew install zlib openssl readline
    CFLAGS="-I$(brew --prefix openssl)/include -I$(brew --prefix readline)/include -I$(xcrun --show-sdk-path)/usr/include"
    LDFLAGS="-L$(brew --prefix openssl)/lib -L$(brew --prefix readline)/lib -L$(brew --prefix zlib)/lib"
    export CFLAGS
    export LDFLAGS
fi

"$python3" ./aws-elastic-beanstalk-cli-setup/scripts/ebcli_installer.py -p "$python3"

# -p /usr/local/bin/python3 avoids this error:
#
#    Traceback (most recent call last):
#      File "/Library/Python/2.7/site-packages/virtualenv.py", line 37, in <module>
#        import ConfigParser
#    ModuleNotFoundError: No module named 'ConfigParser'
#
#    During handling of the above exception, another exception occurred:
#
#    Traceback (most recent call last):
#      File "/Library/Python/2.7/site-packages/virtualenv.py", line 39, in <module>
#        import configparser as ConfigParser
#      File "/Library/Python/2.7/site-packages/configparser/__init__.py", line 11, in <module>
#        raise ImportError('This package should not be accessible on Python 3. '
#    ImportError: This package should not be accessible on Python 3. Either you are trying to run from the python-future src folder or your installation of python-future is corrupted.
