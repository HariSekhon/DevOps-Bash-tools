#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-02-15 13:48:29 +0000 (Fri, 15 Feb 2019)
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

go="${GO:-go}"

usage(){
    echo "Installs Golang tools, taking in to account library paths"
    echo
    echo "Takes a list of go tool names as arguments or .txt files containing lists of tools (one per line)"
    echo
    echo "To skip Golang tools that fail to install, set this in environment:"
    echo
    echo "export GOLANG_SKIP_FAILURES=1"
    echo
    echo "usage: ${0##*} <list_of_tools>"
    echo
    exit 3
}

for x in "$@"; do
    case "$x" in
        -*) usage
            ;;
    esac
done

go_tools=""

process_args(){
    for arg; do
        if [ -f "$arg" ]; then
            echo "adding golang tools from file:  $arg"
            go_tools="$go_tools $(sed 's/#.*//;/^[[:space:]]*$$/d' "$arg")"
            echo
        else
            go_tools="$go_tools $arg"
        fi
    done
}

if [ $# -gt 0 ]; then
    process_args "$@"
else
    # shellcheck disable=SC2046
    process_args $(cat)
fi

if [ -z "${go_tools// }" ]; then
    usage
fi

go_tools="$(tr ' ' ' \n' <<< "$go_tools" | sort -u | tr '\n' ' ')"

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
    go_tool="${go_tool#http?://}"
    if ! [[ "$go_tool" =~ @ ]]; then
        go_tool+="@latest"
    fi
    echo "$envopts $go install $opts $go_tool"
    # want splitting of opts and tools
    # shellcheck disable=SC2086
    if [ -n "${GOLANG_SKIP_FAILURES:-}" ]; then
        set +eo pipefail
        eval $envopts "$go" install $opts "$go_tool"
        set +eu pipefail
    fi
done
