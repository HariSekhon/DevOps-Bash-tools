#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-02-15 13:56:24 +0000 (Fri, 15 Feb 2019)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Installs to --user on Mac to avoid System Integrity Protection built in to OS X El Capitan and later
#
# Also detects and sets up OpenSSL and Kerberos library paths on Mac when using HomeBrew

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/ci.sh"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/python.sh"

# want arg splitting
# shellcheck disable=SC2206
opts=(${PIP_OPTS:-})

usage(){
    echo "Installs Python PyPI modules using Pip, taking in to account library paths, virtual envs etc"
    echo
    echo "Takes a list of python module names as arguments or .txt files containing lists of modules (one per line)"
    echo
    echo "You may need to set this in your environment to install to system or user libraries in newer versions of pip:"
    echo
    echo "  export PIP_BREAK_SYSTEM_PACKAGES=1"
    echo
    echo
    echo "usage: ${0##*} <list_of_modules>"
    echo
    exit 3
}

for arg; do
    case "$arg" in
        -*) usage
            ;;
    esac
done

pip_modules=()

process_args(){
    for arg; do
        if [ -f "$arg" ]; then
            echo "adding pip modules from file:  $arg"
            # want splitting
            # shellcheck disable=SC2207
            pip_modules+=($(sed 's/#.*//;/^[[:space:]]*$$/d' "$arg"))
            echo
        else
            pip_modules+=("$arg")
        fi
    done
}

if [ $# -gt 0 ]; then
    process_args "$@"
else
    # shellcheck disable=SC2046
    process_args $(cat)
fi

if [ -z "${pip_modules[*]}" ]; then
    usage
fi

# want splitting
# shellcheck disable=SC2207
pip_modules=($(tr '[:space:]' ' \n' <<< "${pip_modules[@]}" | sort -u | tr '\n' ' '))

echo "Installing Python PyPI Modules"
echo

if is_CI; then
    #echo "running in quiet mode for CI to minimize log noise"
    opts+=(-q)
fi

sudo=""
if inside_virtualenv; then
    echo "inside virtualenv, not using sudo"
    sudo=""
elif [ $EUID != 0 ]; then
    sudo="sudo --preserve-env=PIP_BREAK_SYSTEM_PACKAGES"
fi

user_opt(){
    if inside_virtualenv; then
        echo "inside virtualenv, ignoring --user switch which wouldn't work"
        sudo=""
    else
        opts+=(--user)
        sudo=""
    fi
}

envopts=()
export LDFLAGS=""
if [ "$(uname -s)" = "Darwin" ]; then
    # setting these caused compile errors failing to find stdio.h when pip installing requests-kerberos
#    if type -P brew &>/dev/null; then
#        # usually /usr/local
#        brew_prefix="$(brew --prefix)"
#
#        export OPENSSL_INCLUDE="$brew_prefix/opt/openssl/include"
#        export OPENSSL_LIB="$brew_prefix/opt/openssl/lib"
#
#        export LDFLAGS="${LDFLAGS:-} -L$brew_prefix/lib"
#        export CFLAGS="${CFLAGS:-} -I$brew_prefix/include"
#        export CPPFLAGS="${CPPFLAGS:-} -I$brew_prefix/include"
#
#        # for OpenSSL
#        export LDFLAGS="${LDFLAGS:-} -L$OPENSSL_LIB"
#        export CFLAGS="${CFLAGS:-} -I$OPENSSL_INCLUDE"
#        export CPPFLAGS="${CPPFLAGS:-} -I$OPENSSL_INCLUDE"
#
#        # for Kerberos
#        export LDFLAGS="${LDFLAGS:-} -L$brew_prefix/opt/krb5/lib"
#        export CFLAGS="${CFLAGS:-} -I$brew_prefix/opt/krb5/include -I $brew_prefix/opt/krb5/include/krb5"
#        export CPPFLAGS="${CPPFLAGS:-} -I$brew_prefix/opt/krb5/include -I $brew_prefix/opt/krb5/include/krb5"
#
#        #export CPATH="${CPATH:-}:$brew_prefix/lib"
#        #export LIBRARY_PATH="${LIBRARY_PATH:-}:$brew_prefix/lib"
#
#        # need to send OPENSSL_INCLUDE and OPENSSL_LIB through sudo explicitly using prefix
#        envopts=(OPENSSL_INCLUDE="$OPENSSL_INCLUDE" OPENSSL_LIB="$OPENSSL_LIB") # LDFLAGS="$LDFLAGS" CFLAGS="$CFLAGS" CPPFLAGS="$CPPFLAGS")
#    fi
    # avoids Mac's System Integrity Protection built in to OS X El Capitan and later
    user_opt
elif [ -n "${PYTHON_USER_INSTALL:-}" ] ||
     [ -n "${GOOGLE_CLOUD_SHELL:-}" ]; then
    user_opt
fi

if [ -n "${NO_FAIL:-}" ]; then
    for pip_module in "${pip_modules[@]}"; do
        # pip defined in lib/python.sh
        # shellcheck disable=SC2154
        echo "$sudo $pip install ${opts[*]:-} $pip_module"
        # want splitting of opts
        # shellcheck disable=SC2068
        $sudo ${envopts[@]:-} "$pip" install ${opts[@]:-} "$pip_module"
    done
else
    echo "$sudo $pip install ${opts[*]:-} ${pip_modules[*]}"
    # want splitting of opts and modules
    # shellcheck disable=SC2068
    $sudo ${envopts[@]:-} "$pip" install ${opts[@]:-} "${pip_modules[@]}"
fi
