#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-04-04 21:22:03 +0100 (Sat, 04 Apr 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

if ! type -P codefresh &>/dev/null; then
    if [ "$(uname -s)" = Darwin ]; then
        echo "Installing codefresh via HomeBrew"
        brew tap codefresh-io/cli
        brew install codefresh
    else
        echo "Installing codefresh via npm"
        npm install codefresh
    fi
fi

if [ -z "${CODEFRESH_KEY:-}" ]; then
    echo "\$CODEFRESH_KEY is not defined"
    exit 1
fi

# generate API key - https://g.codefresh.io/user/settings
echo "creating codefresh auth context"
codefresh auth create-context --api-key "$CODEFRESH_KEY"
