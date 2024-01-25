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
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage(){
    echo "Installs Golang tools not already installed"
    echo
    echo "Leverages adjacent golang_install.sh which takes in to account library paths etc"
    echo
    echo "Takes a list of go tool names as arguments or .txt files containing lists of tools (one per line)"
    echo
    echo "usage: ${0##*} <list_of_tools>"
    echo
    exit 3
}

for arg; do
    case "$arg" in
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

echo "Installing Golang tools that are not already installed"
echo

if [ -n "${GOPATH:-}" ]; then
    export PATH="$PATH:$GOPATH/bin"
fi

for go_tool in $go_tools; do
    go_bin="${go_tool##*/}"
    path="$(type -P "$go_bin" 2>/dev/null || :)"
    if [ -n "$path" ]; then
        echo "go tool '$go_tool' ($go_bin => $path) already installed, skipping..."
    else
        echo "installing go tool '$go_tool'"
        echo
        "$srcdir/golang_install.sh" "$go_tool"
    fi
done
