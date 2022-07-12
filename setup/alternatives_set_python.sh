#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-02-21 09:52:05 +0000 (Fri, 21 Feb 2020)
#  forked from pylib's Makefile from:
#  Original Date: 2013-01-06 15:45:00 +0000 (Sun, 06 Jan 2013)
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
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo=""
[ $EUID -eq 0 ] || sudo=sudo

#$sudo ln -sv -- `type -P python2` /usr/local/bin/python

alternatives(){
    # not available on Alpine
    if type -P alternatives &>/dev/null; then
        $sudo alternatives --set python "$@"
    else
        $sudo ln -sv -- "$1" /usr/local/bin/python
    fi
}

if ! type -P python &>/dev/null; then
    set +e
    python2="$(type -P python2 2>/dev/null)"
    python3="$(type -P python3 2>/dev/null)"
    set -e
    if [ -n "$python3" ]; then
        echo "alternatives: setting python -> $python3"
        # using function wrapper instead for Alpine
        #$sudo alternatives --set python "$python3"
        alternatives "$python3"
    elif [ -n "$python2" ]; then
        echo "alternatives: setting python -> $python2"
        # using function wrapper instead for Alpine
        #$sudo alternatives --set python "$python2"
        alternatives "$python2"
    fi
fi

if ! type -P pip; then
    set +e
    pip2="$(type -P pip2 2>/dev/null)"
    pip3="$(type -P pip3 2>/dev/null)"
    set -e
    if [ -f /usr/local/bin/pip ]; then
        echo "/usr/local/bin/pip already exists, not symlinking - check your \$PATH includes /usr/local/bin (\$PATH = $PATH)"
    elif [ -n "$pip3" ]; then
        $sudo ln -sv -- "$pip3" /usr/local/bin/pip
    elif [ -n "$pip2" ]; then
        $sudo ln -sv -- "$pip2" /usr/local/bin/pip
    else
        $sudo easy_install pip || :
    fi
fi

echo
python -V
echo
"$srcdir/pip_fix_version.sh"
pip -V
echo
