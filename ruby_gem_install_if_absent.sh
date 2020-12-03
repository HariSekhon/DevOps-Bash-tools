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

#ruby="${RUBY:-ruby}"
gem_cmd="${GEM:-gem}"
if type -P "$gem_cmd" &>/dev/null; then
    gem_cmd="$(type -P "$gem_cmd")"
fi

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

for arg; do
    case "$arg" in
        -*) usage
            ;;
    esac
done

gems=""

process_args(){
    for arg; do
        if [ -f "$arg" ]; then
            echo "adding gems from file:  $arg"
            gems="$gems $(sed 's/#.*//;/^[[:space:]]*$$/d' "$arg")"
            echo
        else
            gems="$gems $arg"
        fi
    done
}

if [ $# -gt 0 ]; then
    process_args "$@"
else
    # shellcheck disable=SC2046
    process_args $(cat)
fi

if [ -z "${gems// }" ]; then
    usage
fi

gems="$(tr ' ' ' \n' <<< "$gems" | sort -u | tr '\n' ' ')"

echo "Installing Ruby Gems that are not already installed"
echo

#installed_gems="$("$gem_cmd" list --no-versions | grep -ve '^[[:space:]]*$' -e '^\*')"

for gem in $gems; do
    #if "$ruby" -e "require '$gem'" &>/dev/null; then
    #if grep -Fxq "$gem" <<< "$installed_gems"; then
    # less efficient than above but more likely to not try to re-install packages
    if "$gem_cmd" list --no-versions |
        grep -ve '^[[:space:]]*$' -e '^\*' |
        grep -Fxq "$gem"; then
        echo "ruby gem '$gem' already installed, skipping..."
    else
        echo "installing ruby gem '$gem'"
        echo
        "$srcdir/ruby_gem_install.sh" "$gem"
    fi
done
