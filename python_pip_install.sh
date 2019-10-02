#!/usr/bin/env bash
# shellcheck disable=SC2230
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
#
# Also detects and sets up OpenSSL and Kerberos library paths on Mac when using HomeBrew

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

echo "Installing Python PyPI Modules"
echo

pip_modules=""
for x in "$@"; do
    if [ -f "$x" ]; then
        echo "adding pip modules from file:  $x"
        pip_modules="$pip_modules $(sed 's/#.*//;/^[[:space:]]*$$/d' "$x")"
        echo
    else
        pip_modules="$pip_modules $x"
    fi
    pip_modules="$(tr ' ' ' \n' <<< "$pip_modules" | sort -u | tr '\n' ' ')"
done

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
    if type -P brew &>/dev/null; then
        # usually /opt/local
        brew_prefix="$(brew --prefix)"

        export LDFLAGS="${LDFLAGS:-} -L$brew_prefix/lib"
        export CFLAGS="${CFLAGS:-} -I$brew_prefix/include"
        export CPPFLAGS="${CPPFLAGS:-} -I$brew_prefix/include"

        # for OpenSSL
        export LDFLAGS="${LDFLAGS:-} -L$brew_prefix/opt/openssl/lib"
        export CFLAGS="${CFLAGS:-} -I$brew_prefix/opt/openssl/include"
        export CPPFLAGS="${CPPFLAGS:-} -I$brew_prefix/opt/openssl/include"

        # for Kerberos
        export LDFLAGS="${LDFLAGS:-} -L$brew_prefix/opt/krb5/lib"
        export CFLAGS="${CFLAGS:-} -I$brew_prefix/opt/krb5/include -I $brew_prefix/opt/krb5/include/krb5"
        export CPPFLAGS="${CPPFLAGS:-} -I$brew_prefix/opt/krb5/include -I $brew_prefix/opt/krb5/include/krb5"

        export CPATH="${CPATH:-} $LDFLAGS"
        export LIBRARY_PATH="${LIBRARY_PATH:-} $LDFLAGS"
    fi
    # avoids Mac's System Integrity Protection built in to OS X El Capitan and later
    user_opt
elif [ -n "${PYTHON_USER_INSTALL:-}" ]; then
    user_opt
fi

echo "$SUDO ${PIP:-pip} install $opts $pip_modules"
# want splitting of pip opts
# shellcheck disable=SC2086
$SUDO "${PIP:-pip}" install $opts $pip_modules
