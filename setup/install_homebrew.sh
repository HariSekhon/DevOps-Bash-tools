#!/usr/bin/env bash
#
#  Author: Hari Sekhon
#  Date: 2019-09-12
#
#  https://github.com/harisekhon/devops-bash-tools
#
#  License: see accompanying LICENSE file
#
#  https://www.linkedin.com/in/harisekhon
#

# Install Homebrew on Mac OS X or Linux (used by AWS CLI on Linux)
#
# doesn't install on CentOS 6 any more
#
# https://github.com/Homebrew/brew/issues/7583#issuecomment-640379742

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "${BASH_SOURCE[0]}")"

if type -P brew &>/dev/null; then
    echo "HomeBrew already installed, skipping install..."
else
    echo "==================="
    echo "Installing HomeBrew"
    echo "==================="
    echo
    #if ! type -P git &>/dev/null; then
    #    echo "Must have git installed before installing HomeBrew!"
    #    exit 1
    #fi
    "$srcdir/../install_packages_if_absent.sh" bash git sudo
    if [ "$(uname -s)" = Linux ]; then
        # LinuxBrew has migrated to HomeBrew now
        #curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh |
        curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh |
        {
        # XXX: requires 'sudo' command to install now no matter whether run as root or a regular user :-/
        if [ "$EUID" -eq 0 ]; then
            echo "Installing HomeBrew on Linux as user linuxbrew"
            # Alpine has adduser
            id linuxbrew || useradd linuxbrew || adduser -D linuxbrew
            mkdir -p /home/linuxbrew
            chown -R linuxbrew /home/linuxbrew
            # can't just pass bash, and -s shell needs to be fully qualified path
            su linuxbrew -s /bin/bash
        else
            echo "Installing HomeBrew on Linux as user root"
            # newer verions of HomeBrew require bash not sh due to use of [[
            bash
        fi
        }
    else
        # now deprecated and replaced with the shell version below
        #curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install | ruby
        bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
    fi
fi
