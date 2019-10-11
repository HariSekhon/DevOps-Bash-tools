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

go="${GO:-go}"

usage(){
    echo "Installs Golang tools, taking in to account library paths"
    echo
    echo "Takes a list of go tool names as arguments or .txt files containing lists of tools (one per line)"
    echo
    echo "usage: ${0##*} <list_of_tools>"
    echo
    exit 3
}

go_tools=""
for x in "$@"; do
    if [ -f "$x" ]; then
        echo "adding cpan tools from file:  $x"
        go_tools="$go_tools $(sed 's/#.*//;/^[[:space:]]*$$/d' "$x")"
        echo
    else
        go_tools="$go_tools $x"
    fi
    go_tools="$(tr ' ' ' \n' <<< "$go_tools" | sort -u | tr '\n' ' ')"
done

for x in "$@"; do
    case "$1" in
        -*) usage
            ;;
    esac
done

if [ -z "${go_tools// }" ]; then
    usage
fi

echo "Installing Golang tools"
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

for go_tool in $go_tools; do
    echo "$envopts $go get $opts -u $go_tool"
    # want splitting of opts and tools
    # shellcheck disable=SC2086
    eval $envopts "$go" get $opts -u "$go_tool"
done
