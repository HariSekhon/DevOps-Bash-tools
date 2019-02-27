#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-02-27 11:59:10 +0000 (Wed, 27 Feb 2019)
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

. "$srcdir/utils.sh"

section "Checking for duplicate Perl / Python requirements"

start_time="$(start_timer)"

pip_requirements_files="$(find . -maxdepth 2 -name requirements.txt)"

if [ -n "$pip_requirements_files" ]; then
    echo "Pip PyPI requirements files found: "$pip_requirements_files
    echo "checking for duplicates"
    "$srcdir/find_duplicate_pip_requirements.sh" $pip_requirements_files
    echo
fi

cpan_requirements_files="$(find . -maxdepth 3 -name 'cpan-requirements*.txt')"

if [ -n "$cpan_requirements_files" ]; then
    echo "Perl CPAN requirements files found: "$cpan_requirements_files
    echo "checking for duplicates"
    "$srcdir/find_duplicate_pip_requirements.sh" $cpan_requirements_files
    echo
fi

time_taken "$start_time"
section2 "No duplicate requirements found"
echo
