#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-10-20 12:21:38 +0100 (Tue, 20 Oct 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
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

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Runs 'psql' with colorized output

Uses adjacent psql.sh, see there for more details

Tested on PostgreSQL 8.4, 9.x, 10.x, 11.x, 12.x, 13.0
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<psql_options>]"

# would catch -h but this is a legit option we should let through
#help_usage "$@"

#min_args 1 "$@"

for arg; do
    case "$arg" in
        --help) usage
                ;;
    esac
done

GREEN="$(echo -e '\033[0;32m')"
# RED="$(echo -e '\033[1;31m')"
NOCOLOR="$(echo -e '\033[0m')"

#export LESS="-iMSx4 -FXR"
export LESS="-RFXig --tabs=4"

if type -P less &>/dev/null; then
    pager="less"
else
    pager="more"
fi

sed="sed"
if is_mac; then
    # doesn't work inside PAGER evaluation
    #sed(){
    #    command gsed "$@"
    #}
    sed="command gsed"
fi

                # can't colourize errors because they go to stderr and 2>&1 at start of pager breaks everything
                #s/\(ERROR:\)/$RED\1$NOCOLOR/g;
                #s/^\(\.psqlrc loaded\)/$GREEN\1$NOCOLOR/;
export PAGER="$sed '
                s/^\\(([0-9]\\+ rows*)\\)/$GREEN\\1$NOCOLOR/;
                s/^\\(-\\[\\ RECORD\\ [0-9]\\+\\ \\][-+]\\+\\)/$GREEN\\1$NOCOLOR/;
                s/|/$GREEN|$NOCOLOR/g;
                s/^\\([-+]\\+\\)/$GREEN\\1$NOCOLOR/
                ' 2>&1 |
              $pager"

"$srcdir/psql.sh" --pset pager=always "$@"
