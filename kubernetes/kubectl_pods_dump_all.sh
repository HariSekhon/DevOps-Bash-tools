#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-08-23 10:09:56 +0200 (Fri, 23 Aug 2024)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
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
Runs adjacent kubectl_pod_dump_*.sh scripts a given number of times at given intervals

This is useful to collect support debug information to give to upstream support vendors

num_iterations    - defaults to 1
interval_seconds  - defaults to 300 seconds

If a JDK is specified as a 5th argument then runs an optional

    kubectl_pods_dump_jstacks.sh


Requires kubectl to be installed and configured
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<num_iterations> <interval_seconds> <namespace> <pod_name_regex> <jdk>]"

help_usage "$@"

min_args 1 "$@"
max_args 5 "$@"

num_iterations="${1:-1}"
interval_seconds="${2:-300}"
namespace="${3:-}"
pod_name_regex="${4:-.}"
jdk="${5:-}"

if ! is_int "$num_iterations"; then
    die "First arg - num_iterations - must be an integer!"
fi

if ! is_int "$interval_seconds"; then
    die "Second arg - interval_seconds - must be an integer!"
fi

if ! [ "$interval_seconds" -gt 0 ]; then
    die "Second arg - interval_seconds - must be an integer greater than zero!"
fi

if [ -n "$jdk" ]; then
    if ! [ -f "$jdk/bin/jstack" ]; then
        die "Fifth arg - jdk - must be a directory containing a JDK with jstack!"
    fi
    if ! [ -x "$jdk/bin/jstack" ]; then
        die "jstack within given jdk directory is not executable!"
    fi
fi

for ((i=1; i <= num_iterations; i++)); do
    timestamp "Running iteration $i/$num_iterations of dump all:"
    echo
    cmd=("$srcdir/kubectl_pods_dump_jstacks.sh" "$jdk" ${namespace:+"$namespace" "$pod_name_regex"})
    timestamp "Running: ${cmd[*]}"
    "${cmd[@]}"
    echo
    cmd=("$srcdir/kubectl_pods_dump_stats.sh" ${namespace:+"$namespace" "$pod_name_regex"})
    timestamp "Running: ${cmd[*]}"
    "${cmd[@]}"
    echo
    cmd=("$srcdir/kubectl_pods_dump_logs.sh" ${namespace:+"$namespace" "$pod_name_regex"})
    timestamp "Running: ${cmd[*]}"
    "${cmd[@]}"
    echo
    timestamp "Finished iteration $i of dump all"
    if [ "$num_iterations" -gt "$i" ]; then
        timestamp "Waiting for $interval_seconds seconds before next dump iteration"
        sleep "$interval_seconds"
    fi
    echo
    echo
done
timestamp "All dump iterations completed"
