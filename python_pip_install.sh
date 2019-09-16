#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-02-15 13:56:24 +0000 (Fri, 15 Feb 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Installs to --user on Mac to avoid System Integrity Protection built in to OS X El Capitan and later

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

echo "Installing Python PyPI Modules"

echo "args: $*"

opts=""
if [ -n "${TRAVIS:-}" ]; then
    echo "running in quiet mode"
    opts="-q"
fi

SUDO=""
if [ $EUID != 0 ] &&
   [ -z "${VIRTUAL_ENV:-}" ] &&
   [ -z "${CONDA_DEFAULT_ENV:-}" ]; then
    SUDO=sudo
fi

user_opt(){
    if [ -n "${VIRTUAL_ENV:-}" ] ||
       [ -n "${CONDA_DEFAULT_ENV:-}" ]; then
        echo "inside virtualenv, ignoring --user switch which wouldn't work"
    else
        opts="$opts --user"
        SUDO=""
    fi
}

export LDFLAGS=""
if [ "$(uname -s)" = "Darwin" ]; then
    export LDFLAGS="-I/usr/local/opt/openssl/include -L/usr/local/opt/openssl/lib"
    # avoids Mac's System Integrity Protection built in to OS X El Capitan and later
    user_opt
elif [ -n "${PYTHON_USER_INSTALL:-}" ]; then
    user_opt
fi

echo "$SUDO ${PIP:-pip} install $opts $*"
# want splitting of pip opts
# shellcheck disable=SC2086
$SUDO "${PIP:-pip}" install $opts "$@"
