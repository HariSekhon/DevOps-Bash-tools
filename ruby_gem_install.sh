#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-02-15 13:48:29 +0000 (Fri, 15 Feb 2019)
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

gem="${GEM:-gem}"

usage(){
    echo "Installs Ruby Gems, taking in to account library paths"
    echo
    echo "Takes a list of ruby gem names as arguments or .txt files containing lists of modules (one per line)"
    echo
    echo "usage: ${0##*} <list_of_gems>"
    echo
    exit 3
}

gems=""
for x in "$@"; do
    if [ -f "$x" ]; then
        echo "adding gems from file:  $x"
        gems="$gems $(sed 's/#.*//;/^[[:space:]]*$$/d' "$x")"
        echo
    else
        gems="$gems $x"
    fi
    gems="$(tr ' ' ' \n' <<< "$gems" | sort -u | tr '\n' ' ')"
done

for x in "$@"; do
    case "$1" in
        -*) usage
            ;;
    esac
done

if [ -z "${gems// }" ]; then
    usage
fi

echo "Installing Ruby Gems"
echo

opts=""
if [ -n "${TRAVIS:-}" ]; then
    echo "running in quiet mode"
    opts="-q"
fi

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

sudo=""
if [ $EUID != 0 ]; then
    #sudo=sudo
    opts="$opts --local"
fi

echo "$sudo $envopts $gem install $opts $gems"
# want splitting of opts and gems
# shellcheck disable=SC2086
eval $sudo $envopts "$gem" install $opts $gems
