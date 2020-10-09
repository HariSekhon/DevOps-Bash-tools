#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: Wed Sep 18 14:34:59 2019 +0100
#        (forked from .bash.d/git.sh)
#
#  https://github.com/HariSekhon/bash-tools
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

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Downloads the latest gitignore.io ignore lists to standard output via gitignore.io's API

Useful as a large base to populate your .gitignore, and then sprinkle a few customizations

See the massive .gitignore in this repo for an example of this being used along with the list of common languages
and frameworks passed to this script


Args should be a comma / space separate list of languages and frameworks - see gitignore.io for the full list available

Example:

    ${0##*/} c,python,perl

    ${0##*/} c python perl ruby java scala go
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<langs>"

help_usage "$@"

min_args 1 "$@"

gitignore_api(){
    local url;
    local langs;
    local options=();
    local args=();
    local commas_to_newlines="cat";
    for arg in "$@"; do
        if [ "$arg" = -- ]; then
            options+=("$arg");
        else
            args+=("$arg");
        fi;
    done;
    langs="$(IFS=, ; echo "${args[*]}")";
    url="https://www.gitignore.io/api/$langs";
    if [ "$langs" = "list" ]; then
        commas_to_newlines="tr ',' '\\n'";
    fi;
    {
        if hash curl 2> /dev/null; then
            curl -sSL "${options[@]}" "$url";
        else
            if hash wget 2> /dev/null; then
                wget -O - "${options[*]}" "$url";
            fi;
        fi
    } | eval "$commas_to_newlines";
    echo
}

gitignore_api "$@"
