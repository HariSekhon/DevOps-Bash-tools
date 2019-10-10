#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-09-18 23:21:50 +0100 (Wed, 18 Sep 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Checks if .bashrc and .bash_profile are sourced, otherwise injects source lines in to the $HOME directory equivalents

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"

conf_files="$(sed 's/#.*//; /^[[:space:]]*$/d' "$srcdir/setup/files.conf")"

echo "removing symlinks to dot files in \$HOME directory: $HOME"
echo

for filename in $conf_files .gitignore_global; do
    if [ -L ~/"$filename" ]; then
        rm -fv ~/"$filename" || :
    fi
done

echo
echo "You must manually remove sourcing from ~/.bashrc and ~/.bash_profile"
