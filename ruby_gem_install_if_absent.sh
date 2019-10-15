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

ruby="${RUBY:-ruby}"

usage(){
    echo "Installs Ruby Gems not already installed"
    echo
    echo "Leverages adjacent ruby_gem_install.sh which takes in to account library paths, rubybrew envs etc"
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

if [ -z "$gems" ]; then
    usage
fi

echo "Installing Ruby Gems that are not already installed"
echo

for gem in $gems; do
    if "$ruby" -e "require '$gem'" &>/dev/null; then
        echo "ruby gem '$gem' already installed, skipping..."
    else
        echo "installing ruby gem '$gem'"
        echo
        "$srcdir/ruby_gem_install.sh" "$gem"
    fi
done
