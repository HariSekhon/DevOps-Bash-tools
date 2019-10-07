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

echo "Installing CPAN Modules that are not already installed"
echo

cpan_modules=""
for x in "$@"; do
    if [ -f "$x" ]; then
        echo "adding cpan modules from file:  $x"
        cpan_modules="$cpan_modules $(sed 's/#.*//;/^[[:space:]]*$$/d' "$x")"
        echo
    else
        cpan_modules="$cpan_modules $x"
    fi
    cpan_modules="$(tr ' ' ' \n' <<< "$cpan_modules" | sort -u | tr '\n' ' ')"
done

for cpan_module in $cpan_modules; do
    perl_module="${cpan_module%%@*}"
    if perl -e "use $perl_module;" &>/dev/null; then
        echo "perl cpan module '$perl_module' already installed, skipping..."
    else
        echo "installing perl cpan module '$perl_module'"
        "$srcdir/perl_cpanm_install.sh" "$cpan_module"
    fi
done
