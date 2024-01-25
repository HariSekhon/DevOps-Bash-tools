#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-09-27 17:54:37 +0100 (Fri, 27 Sep 2019)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Shows the path to Perl libraries given as arguments
#
# There is a better version of this in the adjacent DevOps Perl Tools repo called perl_find_library_path.pl

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

perl="${PERL:-perl}"

find_perl_module(){
    cpan_module="$1"
    # shellcheck disable=SC2016
    "$perl" -M"$cpan_module" -e '$path='"$cpan_module"'; $path =~ s/::/\//g; $path =~ s/$/.pm/; print "$INC{$path}\n";'
}

if [ $# -eq 0 ]; then
    find_perl_module "File::Basename" | sed 's,/File/Basename.pm$,,'
fi

for arg; do
    find_perl_module "$arg"
done
