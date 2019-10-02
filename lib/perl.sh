#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2015-05-25 01:38:24 +0100 (Mon, 25 May 2015)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  http://www.linkedin.com/in/harisekhon
#

set -eu
[ -n "${DEBUG:-}" ] && set -x

# Taint code doesn't use PERL5LIB, use -I instead
#I_lib=""

perl="perl"

# shellcheck disable=SC2230
if ! type -P $perl &>/dev/null; then
    return 0 &>/dev/null || :
    exit 0
fi

if [ -n "${PERLBREW_PERL:-}" ]; then

    PERL_VERSION="${PERLBREW_PERL}"
    export PERL_VERSION="${PERLBREW_PERL/perl-/}"

    # For Travis CI which installs modules locally
#    export PERL5LIB=$(echo \
#        ${PERL5LIB:-.} \
#        $PERLBREW_ROOT/perls/$PERLBREW_PERL/lib/site_perl/$PERL_VERSION/x86_64-linux \
#        $PERLBREW_ROOT/perls/$PERLBREW_PERL/lib/site_perl/$PERL_VERSION/darwin-2level \
#        $PERLBREW_ROOT/perls/$PERLBREW_PERL/lib/site_perl/$PERL_VERSION \
#        $PERLBREW_ROOT/perls/$PERLBREW_PERL/lib/$PERL_VERSION/x86_64-linux \
#        $PERLBREW_ROOT/perls/$PERLBREW_PERL/lib/$PERL_VERSION/darwin-2level \
#        $PERLBREW_ROOT/perls/$PERLBREW_PERL/lib/$PERL_VERSION \
#        | tr '\n' ':'
#    )
#
#    for x in $(echo "$PERL5LIB" | tr ':' ' '); do
#        I_lib+="-I $x "
#    done

    sudo=sudo
    # gets this error when not specifying full perl path:
        # Can't load '/home/travis/perl5/perlbrew/perls/5.16/lib/5.16.3/x86_64-linux/auto/re/re.so' for module re: /home/travis/perl5/perlbrew/perls/5.16/lib/5.16.3/x86_64-linux/auto/re/re.so: undefined symbol: PL_valid_types_IVX at /home/travis/perl5/perlbrew/perls/5.16/lib/5.16.3/XSLoader.pm line 68.
        # at /home/travis/perl5/perlbrew/perls/5.16/lib/5.16.3/x86_64-linux/re.pm line 85.
        # Compilation failed in require at /home/travis/perl5/perlbrew/perls/5.16/lib/5.16.3/File/Basename.pm line 44.
        # BEGIN failed--compilation aborted at /home/travis/perl5/perlbrew/perls/5.16/lib/5.16.3/File/Basename.pm line 47.
        # Compilation failed in require at ./check_riak_diag.pl line 25.
        # BEGIN failed--compilation aborted at ./check_riak_diag.pl line 25.
    #perl="$PERLBREW_ROOT/perls/$PERLBREW_PERL/bin/perl $I_lib"
    # shellcheck disable=SC2016
    PERL_MAJOR_VERSION="$($perl -v | $perl -ne '/This is perl (\d+), version (\d+),/ && print "$1.$2"')"
else
    sudo=""
    # shellcheck disable=SC2016
    PERL_MAJOR_VERSION="$($perl -v | $perl -ne '/This is perl (\d+), version (\d+),/ && print "$1.$2"')"
fi
export sudo
export PERL_MAJOR_VERSION
