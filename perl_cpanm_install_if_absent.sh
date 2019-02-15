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

if [ $# == 0 ]; then
    echo "usage: ${0##*/} <filename> <filename> ..."
    exit 1
fi

echo "Installing any CPAN Modules not already present"

cpan_modules="$(sed 's/#.*//; /^[[:space:]]*$$/d' "$@")"

SUDO=""
if [ $EUID != 0 -a -z "${PERLBREW_PERL:-}" ]; then
    SUDO=sudo
fi

for cpan_module in $cpan_modules; do
    perl -e "use $cpan_module;" || ${SUDO} ${CPANM:-cpanm} --notest "$cpan_module"
done
