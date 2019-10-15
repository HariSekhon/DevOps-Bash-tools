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
srcdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

usage(){
    echo "Installs Golang tools not already installed"
    echo
    echo "Leverages adjacent golang_get_install.sh which takes in to account library paths etc"
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
        echo "adding golang tools from file:  $x"
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

echo "Installing Golang tools that are not already installed"
echo

if [ -n "${GOPATH:-}" ]; then
    export PATH="$PATH:$GOPATH/bin"
fi

for go_tool in $go_tools; do
    go_bin="${go_tool##*/}"
    path="$(type -P "$go_bin" 2>/dev/null )"
    # shellcheck disable=SC2181
    if [ $? -eq 0 ]; then
        echo "go tool '$go_tool' ($go_bin => $path) already installed, skipping..."
    else
        echo "installing go tool '$go_tool'"
        echo
        "$srcdir/golang_get_install.sh" "$go_tool"
    fi
done
