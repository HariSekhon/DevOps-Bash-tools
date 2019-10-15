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

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

if type -P brew &>/dev/null; then
    echo "HomeBrew already installed, skipping install..."
else
    echo "==================="
    echo "Installing HomeBrew"
    echo "==================="
    echo
    # automatically sending Enter to Continue
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" <<< ""
fi
