#!/usr/bin/env bash
#
#  Author: Hari Sekhon
#  Date: Aug 2019
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

srcdir="$(dirname "$0")"

if [ "$(uname -s)" = Darwin ]; then
    if ! command -v minishift &>/dev/null; then
        if ! command -v brew &>/dev/null; then
            echo "HomeBrew needs to be installed first, trying to install now"
            "$srcdir/install_homebrew.sh"
        fi
        brew update
        brew cask install minishift
        brew cask install --force minishift
        brew install docker-machine-driver-xhyve
    fi
    sudo chown root:wheel "$(brew --prefix)"/opt/docker-machine-driver-xhyve/bin/docker-machine-driver-xhyve
    sudo chmod u+s /usr/local/opt/docker-machine-driver-xhyve/bin/docker-machine-driver-xhyve
    if ! minishift status | grep -i started; then
        minishift start --vm-driver=virtualbox
    fi
    # .bash.d/kubernetes.sh automatically sources this so 'oc' command is available in all new shells
    minishift oc-env > ~/.minishift.env
else
    echo "Only Mac is supported at this time"
    exit 1
fi
