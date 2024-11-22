#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-11-22 14:22:54 +0400 (Fri, 22 Nov 2024)
#  long overdue port of the adjacent GCP info scripts from years prior
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
. "$srcdir/lib/aws.sh"

script_basename="${0##*/}"
script_basename="${script_basename%%.sh}"
script_basename="${script_basename%%_csv}"

log_timestamp="$(date '+%F_%H.%M.%S')"

# shellcheck disable=SC2034,SC2154
usage_description="
Lists AWS EC2 Instances in quoted CSV format across all configured AWS profiles for their configured region

Combines aws_foreach_profile.sh and aws_info_csv.sh

Outputs to both stdout and a file called $script_basename-YYYY-MM-DD_HH.MM.SS.csv

So that you can diff subsequent runs to see the difference between EC2 VMs that come and go due to AutoScaling Groups


$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

num_args 0 "$@"

csv="$script_basename-$log_timestamp.csv"
csv_sorted="$script_basename-$log_timestamp-sorted.csv"

SECONDS=0

# AWS Virtual Machines
cat >&2 <<EOF
# ============================================================================ #
#          A W S   E C 2   I n v e n t o r y   A l l   A c c o u n t s
# ============================================================================ #

Saving to: $PWD/$csv

Sorted and header deduplicated: $PWD/$csv_sorted

EOF

        # don't do this, solved blank columns natively now so it's easier to spot end of line issues if they end in aa comma instead of ,""
        # see aws_info_ec2_csv.sh where empty fields are now explicitly set to ""
        #s|,$|,\"\"|;

# aws_info_ec2_csv.sh supports fixing the timestamp so we can combine this later
export LOG_TIMESTAMP="$log_timestamp"

aws_foreach_profile.sh "
    '$srcdir/aws_info_ec2_csv.sh' '{profile}' |
    sed '
        s|^|\"{profile}\",|;
        1s|^\"{profile}\"|\"AWS_Profile\"|;
    ' |
    tee <(tail -n +2 >> '$csv_sorted')
" |
tee "$csv"

tmp="$(mktemp)"

# sorting only makes sense when combining a single CSV output format which is why this is EC2 only

# we'd have to combine all the individual CSVs but they have different timestamps, hard to predict, and don't want to make them less granular
head -n1 "$csv" > "$tmp"

#tail -q -n +2 aws_info_ec2-*-"$LOG_TIMESTAMP.csv" |
grep -v '^"AWS_Profile",' "$csv" |
sort -fu >> "$tmp"

mv "$tmp" "$csv_sorted"

echo >&2
aws_foreach_profile.sh "
    grep -q '^\"{profile}\",' ||
    echo 'WARNING: no EC2 Instances found in AWS Profile \"{profile}\"' '$csv_sorted'
" >&2

echo >&2
timestamp "Raw CSV: $csv" >&2
echo >&2
timestamp "Sorted and Header deduplicated CSV: $csv_sorted" >&2
echo >&2
timestamp "Script Completed Successfully in $SECONDS secs: ${0##*/}"
