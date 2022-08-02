#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2015-05-25 01:38:24 +0100 (Mon, 25 May 2015)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -eu
[ -n "${DEBUG:-}" ] && set -x
srcdir_bash_tools_perl="$(dirname "${BASH_SOURCE[0]}")"

# shellcheck disable=SC1090
. "$srcdir_bash_tools_perl/ci.sh"

# to avoid perl: warning: Falling back to the standard locale ("C")
#
# might have to run this on Debian/Ubuntu:
#
# sudo locale-gen en_US.UTF-8
#
# breaks on some systems, probably need to install something for setlocale
#export LANGUAGE="${LANGUAGE:-en_US.UTF-8}"
#export LANG="${LANG:-en_US.UTF-8}"
#export LC_ALL="${LC_ALL:-en_US.UTF-8}"

# Taint code doesn't use PERL5LIB, use -I instead
#I_lib=""

perl="perl"

# shellcheck disable=SC2230
if ! type -P $perl &>/dev/null; then
    if is_CI; then
        if is_mac; then
            find="gfind"
        else
            find="find"
        fi
        echo "WARNING: $perl not found in \$PATH ($PATH)"
        echo
        echo "searching filesystem for Perl:"
        echo
        "$find" / -type f -name perl -executable 2>/dev/null
        echo
    fi >&2
    return 0 &>/dev/null || :
    exit 0
fi

if [ -n "${PERLBREW_PERL:-}" ]; then

    PERL_VERSION="${PERLBREW_PERL}"
    export PERL_VERSION="${PERLBREW_PERL/perl-/}"
    sudo=""

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

    # gets this error when not specifying full perl path:
        # Can't load '/home/travis/perl5/perlbrew/perls/5.16/lib/5.16.3/x86_64-linux/auto/re/re.so' for module re: /home/travis/perl5/perlbrew/perls/5.16/lib/5.16.3/x86_64-linux/auto/re/re.so: undefined symbol: PL_valid_types_IVX at /home/travis/perl5/perlbrew/perls/5.16/lib/5.16.3/XSLoader.pm line 68.
        # at /home/travis/perl5/perlbrew/perls/5.16/lib/5.16.3/x86_64-linux/re.pm line 85.
        # Compilation failed in require at /home/travis/perl5/perlbrew/perls/5.16/lib/5.16.3/File/Basename.pm line 44.
        # BEGIN failed--compilation aborted at /home/travis/perl5/perlbrew/perls/5.16/lib/5.16.3/File/Basename.pm line 47.
        # Compilation failed in require at ./check_riak_diag.pl line 25.
        # BEGIN failed--compilation aborted at ./check_riak_diag.pl line 25.

    #perl="$PERLBREW_ROOT/perls/$PERLBREW_PERL/bin/perl $I_lib"

    # don't want dollars to expand
    # shellcheck disable=SC2016
    PERL_MAJOR_VERSION="$($perl -v | $perl -ne '/This is perl (\d+), version (\d+),/ && print "$1.$2"')"
else
    PERL_VERSION="$(perl --version | grep -Eom 1 'v[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+' | sed 's/^v//')"
    # don't want dollars to expand
    # shellcheck disable=SC2016
    PERL_MAJOR_VERSION="$($perl -v | $perl -ne '/This is perl (\d+), version (\d+),/ && print "$1.$2"')"
fi

I_lib=""
PERL5LIB="${PERL5LIB:-}"
# because PERL5LIB is not respected in Taint mode, but -I is because it's more explicit
for x in ${PERL5LIB//:/ }; do
    I_lib+="-I $x "
done
# this breaks a lot of stuff because client code rightly assumes to run "$perl"
#perl="$perl $I_lib"

export sudo
export PERL_VERSION
export PERL_MAJOR_VERSION
