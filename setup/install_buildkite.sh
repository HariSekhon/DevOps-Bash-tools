#!/usr/bin/env bash
#
#  Author: Hari Sekhon
#  Date: 2020-03-11 17:49:09 +0000 (Wed, 11 Mar 2020)
#
#  https://github.com/harisekhon/devops-bash-tools
#
#  License: see accompanying LICENSE file
#
#  https://www.linkedin.com/in/harisekhon
#

# Installs Circle CI using Homebrew on Mac or direct download to ~/bin otherwise

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

# shellcheck disable=SC1090
. "$srcdir/../lib/utils.sh"

section "Installing BuildKite Agent"

# path on Mac
export PATH="$PATH:/usr/local/bin"

if is_linux; then
    export PATH="$PATH:$HOME/.buildkite-agent/bin"
fi

if [ -z "${BUILDKITE_TOKEN:-}" ]; then
    echo "BUILDKITE_TOKEN environment variable not defined"
    exit
fi

if type -P buildkite-agent &>/dev/null; then
    if is_mac; then
        config=/usr/local/etc/buildkite-agent/buildkite-agent.cfg
        if [ -f "$config" ]; then
            if ! grep "$BUILDKITE_TOKEN" "$config"; then
                echo "injecting buildkite token into $config"
                sed -i.bak "s/^token=.*/token=$BUILDKITE_TOKEN/" "$config"
            fi
        fi
    fi
    echo "buildkite-agent is already installed"
    exit 0
fi

if is_mac; then
    brew tap buildkite/buildkite
    # inserts token in to /usr/local/etc/buildkite-agent/buildkite-agent.cfg
    brew install --token="$BUILDKITE_TOKEN" buildkite-agent
    # run as a background agent
    # brew services start buildkite/buildkite/buildkite-agent
    # run as foreground agent
    buildkite-agent start
else
    TOKEN="$BUILDKITE_TOKEN" bash -c "$(curl -sL https://raw.githubusercontent.com/buildkite/agent/master/install.sh)"
    ~/.buildkite-agent/bin/buildkite-agent start
fi
