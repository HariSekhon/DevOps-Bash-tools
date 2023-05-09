#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-09-18 23:21:50 +0100 (Wed, 18 Sep 2019)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Checks if .bashrc and .bash_profile are sourced, otherwise injects source lines in to the $HOME directory equivalents

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash_tools="$srcdir/.."

conf_files="$(sed 's/#.*//; /^[[:space:]]*$/d' "$bash_tools/setup/files.txt")"

# unreliable that HOME is set, ensure shell evaluates to the right thing before we use it
[ -n "${HOME:-}" ] || HOME=~

echo "removing symlinks to dot files in \$HOME directory: $HOME"
echo

for filename in $conf_files .gitignore_global; do
    filename="${filename#configs}"
    filename="${filename#/}"
    if [ -L ~/"$filename" ]; then
        rm -fv -- ~/"$filename" || :
    fi
done

echo

remove_sourcing(){
    local filename="$1"
    if ! grep -Eq "^[[:space:]]*(source|\\.)[[:space:]]+$bash_tools/$filename" ~/"$filename" 2>/dev/null; then
        echo "$filename not currently sourced in ~/$filename"
    else
        echo "in-place editing ~/$filename to remove sourcing of $bash_tools/$filename"
        local bash_tools_escaped="${bash_tools//\//\\/}"
        local filename_escaped="${filename//\//\\/}"
        perl -ni".bak-$(date '+%F_%H%M')" -e "print unless /(source|\\.)[[:space:]]+$bash_tools_escaped\\/$filename_escaped/" ~/"$filename"
    fi
}

remove_sourcing .bashrc
remove_sourcing .bash_profile
