#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-09-11 15:45:57 +0100 (Fri, 11 Sep 2020)
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
Finds and deletes stuck Kubernetes jobs using the criteria specified in the adjacent script kubernetes_find_stuck_jobs.sh which this script calls

Shows the jobs and prompts for confirmation before deleting them

This assumes that your jobs are being run by cronjobs and will be recreated
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<kubectl_options>]"

help_usage "$@"

stuck_jobs="$(kubectl_jobs_stuck.sh "$@")"
header="$(head -n1 <<< "$stuck_jobs")"
stuck_jobs="$(tail -n +2 <<< "$stuck_jobs")"

if [ -z "$stuck_jobs" ]; then
    exit 0
fi

echo "Jobs to delete:"
echo
echo "$header"
echo "$stuck_jobs"
echo
read -r -p "Are you sure you want to delete these jobs? (y/N) " answer

shopt -s nocasematch

if ! [[ "$answer" =~ y|yes ]]; then
    timestamp "Aborting..."
    exit 1
fi

timestamp "Deleting stuck kubernetes jobs"

awk '!/^NAME/{print $1}' <<< "$stuck_jobs" |
xargs kubectl delete jobs "$@"
