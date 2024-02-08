#!/usr/bin/env bash
# shellcheck disable=SC2230
#
#  Author: Hari Sekhon
#  Date: Aug 2019
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying LICENSE file
#
#  https://www.linkedin.com/in/HariSekhon
#

# Installs MiniShift on Mac - needs VirtualBox to be installed first

#set -euo pipefail
set -u

#[ -n "${DEBUG:-}" ] &&
set -x

srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$(uname -s)" = Darwin ]; then
    if ! type -P minishift &>/dev/null; then
        if ! type -P brew &>/dev/null; then
            echo "HomeBrew needs to be installed first, trying to install now"
            "$srcdir/install_homebrew.sh"
        fi
        brew update
        brew cask install minishift
        brew cask install --force minishift
        brew install docker-machine-driver-xhyve
    fi
    brew_prefix="$(brew --prefix)"
    sudo chown root:wheel "$brew_prefix"/opt/docker-machine-driver-xhyve/bin/docker-machine-driver-xhyve
    sudo chmod u+s "$brew_prefix"/opt/docker-machine-driver-xhyve/bin/docker-machine-driver-xhyve
    if [ -z "${NO_START:-}" ] &&
       [ -z "${QUICK:-}" ]; then
       # quicker to just try, it'll tell you if it's already running
       #! minishift status | grep -i Running; then
        minishift start --vm-driver=virtualbox
    fi
    # .bash.d/kubernetes.sh automatically sources this so 'oc' command is available in all new shells
    # fails if no running minishift VM - in which case remove the .minishift.env to avoid errors on every new shell
    minishift oc-env > ~/.minishift.env || rm -f -- ~/.minishift.env
else
    echo "Only Mac is supported at this time"
    exit 1
fi
