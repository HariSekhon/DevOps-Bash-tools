#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  shellcheck disable=SC2028
#
#  Author: Hari Sekhon
#  Date: 2020-08-09 10:42:23 +0100 (Sun, 09 Aug 2020)
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
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

mariadb_versions="5.5 10.0 10.1 10.2 10.3 10.4 10.5 latest"

# shellcheck disable=SC2034,SC2154
usage_description="
Runs all of the scripts given as arguments against multiple MariaDB versions using docker

Uses mariadb.sh to boot a MariaDB docker environment and pipe source statements in to the container

Sources each script in MariaDB in the order given

If \$MARIADB_VERSIONS environment variable is set, then only tests against those versions,
otherwise if dockerhub_show_tags.py is found in the \$PATH (from DevOps Python tools repo),
then uses it to fetches the latest live list of version tags available from the dockerhub API,
otherwise falls back to the following pre-set list of versions:

$(tr ' ' '\n' <<< "$mariadb_versions")
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="script1.sql [script2.sql ...]"

help_usage "$@"

min_args 1 "$@"

for sql in "$@"; do
    [ -f "$sql" ] || die "ERROR: file not found: $sql"
done

if [ -n "${MARIADB_VERSIONS:-}" ]; then
    mariadb_versions="${MARIADB_VERSIONS//,/ }"
    echo "using given MariaDB versions:"
else
    #echo "checking if dockerhub_show_tags.py is available:"
    #echo
    #if type -P dockerhub_show_tags.py 2>/dev/null; then
    #    echo
    #    echo "dockerhub_show_tags.py found, executing to get latest list of MariaDB docker version tags"
    #    echo
    #    mariadb_versions="$(dockerhub_show_tags.py mariadb |
    #                        grep -Eo '[[:space:]][[:digit:]]{1,2}\.[[:digit:]]' |
    #                        sed 's/[[:space:]]//g' |
    #                        sort -u -t. -k1n -k2n)"
    #    echo "found MariaDB versions:"
    #else
        echo "using default list of MariaDB versions to test against:"
    #fi
fi
echo
tr ' ' '\n' <<< "$mariadb_versions"
echo

for version in $mariadb_versions; do
    {
    echo '\! printf "================================================================================\n"'
    echo 'SELECT VERSION();'
    for sql in "$@"; do
        # no effect
        #echo
        # comes out first instead of with scripts
        #echo "\\! printf '\nscript %s:' '$sql'"
        echo "select '$sql' as script;"
        # instead of dealing with pathing issues, prefixing /pwd or depending on the scripts being in the sql/ directory
        #echo "source $sql"
        cat "$sql"
        #echo "\\! printf '\n\n'"
    done
    } |
    # need docker run non-interactive to avoid tty errors
    # forcing mysql shell --table output as though interactive
    DOCKER_NON_INTERACTIVE=1 \
    MYSQL_OPTS="--table" \
    "$srcdir/mariadb.sh" "$version"
done
