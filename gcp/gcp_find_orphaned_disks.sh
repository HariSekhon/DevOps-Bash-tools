#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-28 10:22:49 +0100 (Fri, 28 Aug 2020)
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
Finds orphaned disks across one or more GCP Projects using GCloud SDK

This is done by finding disks in each project with no 'users' (instances attached)

Output format:

<project_id>    <zone>    <type>    <sizeGB>    <disk_name>
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<project>]"

help_usage "$@"

if [ $# -gt 0 ]; then
    tr '[:space:]' '\n' <<< "$@"
else
    gcloud projects list --format="get(project_id)"
fi |
while read -r project_id; do
    # XXX: for disks that have always been in use lastDetachTimestamp may not exist and result in false positives
    gcloud compute disks list --format="table[no-heading](name, zone.basename(), type.basename(), sizeGb, users.join(','))" --project "$project_id" |
    while read -r disk zone type size users; do
        [ -n "$users" ] && continue
        printf '%s\t%s\t%s\t%s\t%s\n' "$project_id" "$zone" "$type" "$size" "$disk"
    done
done
