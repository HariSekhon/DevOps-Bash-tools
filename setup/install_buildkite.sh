#!/usr/bin/env bash
#
#  Author: Hari Sekhon
#  Date: 2020-03-11 17:49:09 +0000 (Wed, 11 Mar 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying LICENSE file
#
#  https://www.linkedin.com/in/HariSekhon
#

# Installs BuildKite using Homebrew on Mac or direct download to ~/bin otherwise

# https://buildkite.com/organizations/hari-sekhon/agents#setup-linux
#
# https://buildkite.com/organizations/hari-sekhon/agents#setup-macos

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/../lib/utils.sh"

section "Installing BuildKite Agent"

# path on Mac
export PATH="$PATH:/usr/local/bin"

if is_linux; then
    # unreliable that HOME is set, ensure shell evaluates to the right thing before we use it
    [ -n "${HOME:-}" ] || HOME=~
    export PATH="$PATH:$HOME/.buildkite-agent/bin"
fi

if [ -z "${BUILDKITE_AGENT_TOKEN:-}" ]; then
    echo "BUILDKITE_AGENT_TOKEN environment variable not defined"
    exit 1
fi

if type -P buildkite-agent &>/dev/null; then
    echo "** buildkite-agent is already installed"
elif is_mac; then
    brew tap buildkite/buildkite
    brew install buildkite-agent
else
    TOKEN="$BUILDKITE_AGENT_TOKEN" bash -c "$(curl -sL https://raw.githubusercontent.com/buildkite/agent/master/install.sh)"
fi

if is_mac; then
    config=/usr/local/etc/buildkite-agent/buildkite-agent.cfg
    if [ -f "$config" ]; then
        if grep -q "$BUILDKITE_AGENT_TOKEN" "$config"; then
            echo "** \$BUILDKITE_AGENT_TOKEN already found in config"
        else
            echo
            echo "** injecting buildkite token into config: $config"
            echo
            sed -i.bak "s/^token=.*/token=$BUILDKITE_AGENT_TOKEN/" "$config"
        fi
    fi
    # run as a background agent
    # brew services start buildkite/buildkite/buildkite-agent
    # run as foreground agent
    buildkite-agent start
else
    ~/.buildkite-agent/bin/buildkite-agent start
fi
