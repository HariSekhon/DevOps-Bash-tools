#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2016-01-15 00:33:52 +0000 (Fri, 15 Jan 2016)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"
# shellcheck disable=SC1090
. "$srcdir/lib/docker.sh"

#return 0 &>/dev/null || :
#exit 0

section "Travis CI Yaml Lint Check"

start_time="$(start_timer)"

if is_travis; then
    echo "Running inside Travis CI, skipping lint check"
elif is_inside_docker; then
    echo "Running inside Docker, skipping lint check"
else
    # sometimes ~/.gem/ruby/<version>/bin may not be in $PATH but this succeeds anyway if hashed in shell
    #if ! type travis &>/dev/null; then
    for path in ~/.gem/ruby/*; do
        [ -d "$path" ] || continue
        export PATH="$PATH:$path/bin"
    done
    if ! command -v travis &>/dev/null; then
        if command -vgem &>/dev/null; then
            # this returns ruby-1.9.3 but using 1.9.1
            #ruby_version="$(ruby --version | awk '{print $2}' | sed 's/p.*//')"
            #export PATH="$PATH:$HOME/.gem/ruby/$ruby_version/bin"
            echo "installing travis gem... (requires ruby-dev package to be installed)"
            gem install --user-install travis --no-rdoc --no-ri
            for path in ~/.gem/ruby/*; do
                [ -d "$path" ] || continue
                export PATH="$PATH:$path/bin"
            done
        else
            echo "WARNING: skipping Travis install as gem command was not found in \$PATH"
            echo
        fi
    fi
    if command -v travis &>/dev/null; then
        travis lint
    else
        echo "WARNING: skipping Travis check as Travis is not installed"
    fi
fi

echo
time_taken "$start_time"
section2 "Travis CI yaml validation succeeded"
echo
