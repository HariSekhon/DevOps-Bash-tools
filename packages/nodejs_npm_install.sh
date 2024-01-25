#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-10-23 10:41:56 +0100 (Wed, 23 Oct 2019)
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

npm="${NPM:-npm}"

usage(){
    echo "Installs NodeJS NPM packages"
    echo
    echo "Automatically set to install globally if run as root"
    echo
    echo "Takes a list of npm package names as arguments or .txt files containing lists of modules (one per line)"
    echo
    echo "usage: ${0##*} <list_of_packages>"
    echo
    exit 3
}

for arg; do
    case "$arg" in
        -*) usage
            ;;
    esac
done

packages=""

process_args(){
    for arg; do
        if [ -f "$arg" ]; then
            echo "adding packages from file:  $arg"
            packages="$packages $(sed 's/#.*//;/^[[:space:]]*$$/d' "$arg")"
            echo
        else
            packages="$packages $arg"
        fi
    done
}

if [ $# -gt 0 ]; then
    process_args "$@"
else
    # shellcheck disable=SC2046
    process_args $(cat)
fi

if [ -z "${packages// }" ]; then
    usage
fi

packages="$(tr ' ' ' \n' <<< "$packages" | sort -u | tr '\n' ' ')"

echo "Installing NodeJS NPM packages"
echo

opts=""
#if [ -n "${TRAVIS:-}" ]; then
#    echo "running in quiet mode"
#    opts="-q"
#fi

envopts=""
if [ "$(uname -s)" = "Darwin" ]; then
    if type -P brew &>/dev/null; then
        # usually /usr/local
        brew_prefix="$(brew --prefix)"
        # needed to build Crypt::SSLeay
        export OPENSSL_INCLUDE="$brew_prefix/opt/openssl/include"
        export OPENSSL_LIB="$brew_prefix/opt/openssl/lib"
        # need to send OPENSSL_INCLUDE and OPENSSL_LIB through sudo explicitly using prefix
        envopts="OPENSSL_INCLUDE=$OPENSSL_INCLUDE OPENSSL_LIB=$OPENSSL_LIB"
    fi
fi

if [ $EUID = 0 ]; then
    opts="-g"
fi

echo "$envopts $npm install $opts $packages"
# want splitting of opts and packages
# shellcheck disable=SC2086
eval $envopts "$npm" install $opts $packages
