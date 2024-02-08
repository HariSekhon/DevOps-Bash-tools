#!/usr/bin/env bash
# vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-09-19 11:26:11
#  (moved from Makefile)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying LICENSE file
#
#  https://www.linkedin.com/in/HariSekhon
#

# Installs AWLess

# You might need to first:
#
# yum install -y epel-release
# yum install -y gcc git make python-pip which
#
# this is automatically done first when called via 'make aws' at top level of this repo

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/../lib/utils.sh"

# shellcheck disable=SC1090,SC1091
. "$srcdir/../lib/ci.sh"

section "Installing AWLess"

mkdir -p ~/bin

# unreliable that HOME is set, ensure shell evaluates to the right thing before we use it
[ -n "${HOME:-}" ] || HOME=~

export PATH="$PATH:/usr/local/bin"
export PATH="$PATH:$HOME/bin"

if type -P awless &>/dev/null; then
    echo "Awless already installed"
else
    echo
    echo "=========================="
    echo "Awless is unmaintained now, installing only optimistically and ignoring failures..."
    echo "=========================="
    echo
    set +e
    echo "Installing AWLess"
    if is_mac; then
        # this brew install fails on Linux even when brew is installed and works for SAM CLI
        brew tap wallix/awless
        echo
        brew install awless
    else
        if ! curl -sS https://updates.awless.io >/dev/null; then
            #echo
            #echo "AWLess SSL certificate still expired, must install manually until fixed"
            "$srcdir/getawless.sh"
        else
            curl -sS https://raw.githubusercontent.com/wallix/awless/master/getawless.sh | bash
        fi
        mv -iv -- awless ~/bin/
    fi
fi

# Awless is usually installed to /usr/local/bin/awless

cat <<EOF

Done

Installed to:

$(type -P awless)

EOF
