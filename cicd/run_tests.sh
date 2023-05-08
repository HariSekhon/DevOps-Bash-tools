#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2016-01-23 17:19:22 +0000 (Sat, 23 Jan 2016)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/utils.sh
. "$srcdir/lib/utils.sh"

# shellcheck source=lib/docker.sh
. "$srcdir/lib/docker.sh"

section "Running Test Scripts"

declare_if_inside_docker

start_time="$(start_timer)"

filter="${1:-.*}"
search_dir="${2:-.}"

scripts="$(find "$search_dir" -maxdepth 2 -type f -iname 'test_*.sh' | grep -E -- "test_$filter" | sort -f || :)"

for script in $scripts; do
    date
    script_start_time="$(date +%s)"
    echo
    declare_if_inside_docker
    # quoting VERSION passes blank which prevents populating with default versions
    # shellcheck disable=SC2086
    "./$script" ${VERSION:-}
    echo
    date
    echo
    script_end_time="$(date +%s)"
    script_time_taken="$((script_end_time - script_start_time))"
    echo "Completed in $script_time_taken secs"
done

time_taken "$start_time"
section2 "Test Scripts Completed"
echo
