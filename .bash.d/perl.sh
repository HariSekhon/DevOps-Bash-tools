#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: circa 2006 (forked from .bashrc)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# ============================================================================ #
#                                    P e r l
# ============================================================================ #

bash_tools="${bash_tools:-$(dirname "${BASH_SOURCE[0]}")/..}"

# shellcheck disable=SC1090,SC1091
#. "$bash_tools/.bash.d/os_detection.sh"

#type add_PATH &>/dev/null || . "$bash_tools/.bash.d/paths.sh"

if [ -d ~/perl5/bin ]; then
    add_PATH ~/perl5/bin
fi

# see the effect of inserting a path like so
# PERL5LIB=/path/to/blah perlpath
perlpath(){
    perl -e 'print join("\n", @INC) . "\n";'
}

# XXX: Perl Taint mode resets and restricts the Perl Path to not use PERL5LIB for security
#
#   scripts like those in the Advanced Nagios Plugins Collection and DevOps-Perl-tools will need to add lib
#
#if [ -d /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/System/Library/Perl/ ]; then
#    add_PATH PERL5LIB /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/System/Library/Perl
#fi
if [ -d ~/perl5/lib/perl5 ]; then
    #add_PATH PERL5LIB ~/perl5/lib/perl5
    #export PERL5LIB="$PERL5LIB:$HOME/perl5/lib/perl5"
    if ! [[ "${PERL5LIB:-}" == *"$HOME/perl5/lib/perl5"* ]]; then
        export PERL5LIB=~/perl5/lib/perl5"${PERL5LIB+:$PERL5LIB}"
    fi

fi
if ! [[ "${PERL_LOCAL_LIB_ROOT:-}" == *"$HOME/perl5"* ]]; then
    export PERL_LOCAL_LIB_ROOT="$HOME/perl5${PERL_LOCAL_LIB_ROOT+:$PERL_LOCAL_LIB_ROOT}"
fi
export PERL_MB_OPT="--install_base '$HOME/perl5'"
export PERL_MM_OPT="INSTALL_BASE=$HOME/perl5"

alias lsperlbin='ls -d ~/perl5/bin/* 2>/dev/null'
alias llperlbin='ls -ld ~/perl5/bin/* 2>/dev/null'

# cpanm --local-lib=~/perl5 local::lib
# populates a bunch of Perl env vars pointing to ~/perl5/...
# eval "$(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)"
