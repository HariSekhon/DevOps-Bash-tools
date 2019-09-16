#!/usr/bin/env bash
#
#  Author: Hari Sekhon
#  Date: 2019-09-16
#
#  https://github.com/harisekhon/devops-bash-tools
#
#  License: see accompanying LICENSE file
#
#  https://www.linkedin.com/in/harisekhon
#

# Installs MiniShift on Mac - needs VirtualBox to be installed first

#set -euo pipefail
set -u

#[ -n "${DEBUG:-}" ] &&
set -x

if [ "$(uname -s)" = Darwin ]; then
    brew cask install minishift
    brew cask install --force minishift
    brew install docker-machine-driver-xhyve
    sudo chown root:wheel "$(brew --prefix)"/opt/docker-machine-driver-xhyve/bin/docker-machine-driver-xhyve
    sudo chmod u+s /usr/local/opt/docker-machine-driver-xhyve/bin/docker-machine-driver-xhyve
    minishift start --vm-driver=virtualbox
    minishift oc-env > ~/.minishift.env
else
    echo "Only Mac is supported at this time"
    exit 1
fi
