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

# Install Homebrew on Mac OS X
#
# doesn't install on CentOS 6 any more
#
# https://github.com/Homebrew/brew/issues/7583#issuecomment-640379742

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

if type -P brew &>/dev/null; then
    echo "HomeBrew already installed, skipping install..."
else
    echo "==================="
    echo "Installing HomeBrew"
    echo "==================="
    echo
    if ! type -P git &>/dev/null; then
        echo "Must have git installed before installing HomeBrew!"
        exit 1
    fi
    # automatically sending Enter to Continue
    if [ "$(uname -s)" = Linux ]; then
        curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh |
        {
        if [ "$EUID" -eq 0 ]; then
            # Alpine has adduser
            id linuxbrew || useradd linuxbrew || adduser -D linuxbrew
            mkdir -p /home/linuxbrew
            chown -R linuxbrew /home/linuxbrew
            su linuxbrew
        else
            sh
        fi
        }
    else
        # now deprecated and replaced with the shell version belownow
        #curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install | ruby
        bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
    fi
fi
