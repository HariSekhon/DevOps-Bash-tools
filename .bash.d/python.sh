#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: circa 2006 (forked from .bashrc)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# ============================================================================ #
#                                  P y t h o n
# ============================================================================ #

bash_tools="${bash_tools:-$(dirname "${BASH_SOURCE[0]}")/..}"

# shellcheck disable=SC1090,SC1091
. "$bash_tools/.bash.d/os_detection.sh"

# silence those annoying Python 2 cryptography warnings that mess up our programs outputs
export PYTHONWARNINGS=ignore::UserWarning

# shellcheck disable=SC1090,SC1091
type add_PATH &>/dev/null || . "$bash_tools/.bash.d/paths.sh"

# see the effect of inserting a path like so
# PYTHONPATH=/path/to/blah pythonpath
pythonpath(){
    python -c 'from __future__ import print_function; import sys; [print(_) for _ in sys.path if _]'
}
# enable this to avoid creating .pyc files (sometimes they trip you up executing outdated python code)
# export PYTHONDONTWRITEBYTECODE=1

if is_mac; then
    # try to find pip in brew installed Python versions since it is
    # not in /System/Library/Frameworks/Python.framework/Versions/2.7/bin
    for dir in /usr/local/Cellar/python*; do
        if [ -d "$dir" ]; then
            add_PATH "$dir/bin"
        fi
    done
fi

if [ -d ~/Library/Python ]; then
    for x in ~/Library/Python/*/bin; do
        [ -d "$x" ] || continue
        add_PATH "$x"
    done
fi

alias lspythonbin='ls -d ~/Library/Python/*/bin/* 2>/dev/null'
alias llpythonbin='ls -ld ~/Library/Python/*/bin/* 2>/dev/null'
alias lspybin=lspythonbin
alias llpybin=llpythonbin

# RHEL8 has split python2 / python3 and removed default 'python' :-(
if ! type -P python &>/dev/null; then
    if type -P python2 &>/dev/null; then
        python(){ python2 "$@"; }
    elif type -P python3 &>/dev/null; then
        python(){ python3 "$@"; }
    fi
fi
