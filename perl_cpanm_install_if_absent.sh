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

echo "Installing CPAN Modules listed in file(s): $*"

opts=""
if [ -n "${TRAVIS:-}" ]; then
    echo "running in quiet mode"
    opts="-q"
fi

if [ "$(uname -s)" = "Darwin" ]; then
    # needed to build Crypt::SSLeay
    export OPENSSL_INCLUDE=/usr/local/opt/openssl/include
    export OPENSSL_LIB=/usr/local/opt/openssl/lib
fi

cpan_modules="$(cat "$@" | sed 's/#.*//; /^[[:space:]]*$$/d' | sort -u)"

SUDO=""
if [ $EUID != 0 ] &&
   [ -z "${PERLBREW_PERL:-}" ]; then
    SUDO=sudo
fi

for cpan_module in $cpan_modules; do
    perl_module="${cpan_module%%@*}"
    if ! perl -e "use $perl_module;" &>/dev/null; then
        echo "Installing $perl_module"
        # need to send OPENSSL_INCLUDE and OPENSSL_LIB through sudo explicitly
        $SUDO \
            OPENSSL_INCLUDE="$OPENSSL_INCLUDE" \
            OPENSSL_LIB="$OPENSSL_LIB" \
            "${CPANM:-cpanm}" $opts --notest "$cpan_module"
    fi
done
