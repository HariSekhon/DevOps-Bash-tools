#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2017-10-08 16:57:51 +0100 (Sun, 08 Oct 2017)
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

# shellcheck source=lib/utils.sh
. "$srcdir/lib/utils.sh"

section "Checking all test_*.sh run calls are fully qualified"

failed_count=0
scripts="$(find "${1:-.}" -maxdepth 2 -type f -name 'test*.sh')"
#while read script; do
# doesn't handle whitespace in names but makes global variable access easier we don't use whitespace in names in unix
for script in $scripts; do
    # this fails files broken on whitespace immediately, will count as 2 of more separate files not found
    echo -n "checking script $script => "
    if ! [ -f "$script" ]; then
        ((failed_count + 1))
        echo "NOT FOUND"
        continue
    fi
    set +eo pipefail
                     # don't anchor grep -v as we're prefixing line numbers for convenience
    # run
    # run_fail \d+
    # run_fail "\d+ \d+ ..."
    # run_conn_refused
    # run_usage
    # run_404
    # run_timeout
    run_fail='run(_[a-z]+[[:digit:]]* "?[[:digit:][:space:]]+"?|_conn_refused|_usage|_404|_timeout)?'
    # docker-compose or docker exec or docker run
    docker_regex='docker(-compose|[[:space:]]+(exec|run))'
    # want $bin in regex
    # shellcheck disable=SC2016
    suspect_lines="$(grep -En '^[[:space:]]*run(_.+)?[[:space:]]+' "$script" |
                     grep -Ev -e "[[:space:]]*${run_fail}[[:space:]](.*[[:space:]])?(./|(\\\$perl|eval|$docker_regex)[[:space:]])" \
                              -e '[[:space:]]*run_test_versions' \
                              -e '[[:space:]]*run_(grep|output)[[:space:]].+(\$|./)' \
                              -e 'ignore_run_unqualified' \
                              -e '\$bin/' \
                              # run_grep filter is not that accurate but will do for now
                              # ignore golang tests where we do run "$bin/binary"
                    )"
    set -eo pipefail
    if [ -n "$suspect_lines" ]; then
        ((failed_count + 1))
        echo "Suspect lines detected!"
        echo
        echo "$suspect_lines"
        echo
    else
        echo "OK"
    fi
done

if [ "$failed_count" = 0 ]; then
    echo
    echo 'Passed checks'
    echo
else
    echo
    echo "$failed_count scripts with non-qualified command run arguments detected!"
    exit 1
fi
