#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-04-16 21:51:27 +0100 (Thu, 16 Apr 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
#srcdir_bash_tools_python="$(dirname "${BASH_SOURCE[0]}")"

# shellcheck disable=SC1090
#. "$srcdir_bash_tools_python/ci.sh"

# shellcheck disable=SC1090
#. "$srcdir_bash_tools_python/os.sh"

inside_ruby_virtualenv(){
    # $HOME/.rbenv/shims/ruby
    if inside_rvm || inside_rbenv; then
        return 0
    fi
    return 1
}

inside_rbenv(){
    # $HOME/.rbenv/shims/ruby
    if command -v ruby | grep -q -e '/\.rbenv/'; then
        return 0
    fi
    return 1
}

inside_rvm(){
    if command -v ruby | grep -q -e '/\.rvm/'; then
        return 0
    fi
    return 1
}
