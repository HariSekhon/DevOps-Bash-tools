#!/usr/bin/env bash
#
#  Author: Hari Sekhon
#  Date: 2020-03-19 19:31:41 +0000 (Thu, 19 Mar 2020)
#
#  https://github.com/harisekhon/devops-bash-tools
#
#  License: see accompanying LICENSE file
#
#  https://www.linkedin.com/in/harisekhon
#

# Install Docker Compose

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

if type -P docker-compose &>/dev/null; then
    echo "Docker Compose already installed, skipping install..."
else
    echo "========================="
    echo "Installing Docker Compose"
    echo "========================="
    echo
    dir=~/bin
    mkdir -pv "$dir"
    wget -c "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -O "$dir/docker-compose"
    chmod +x "$dir/docker-compose"
fi
