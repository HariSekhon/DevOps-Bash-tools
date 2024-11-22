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

# shellcheck disable=SC2034,SC2154
usage_description="
Gathers AWS Info across all projects in CSV format

Combines aws_foreach_profile.sh and aws_info_csv.sh

Outputs to both stdout and a file called aws_info_all_profiles-YYYY-MM-DD_HH.MM.SS.csv

So that you can diff subsequent runs to see the difference between EC2 VMs that come and go due to AutoScaling Groups


$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

num_args 0 "$@"

        # don't do this, solved blank columns natively now so it's easier to spot end of line issues if they end in aa comma instead of ,""
        # see aws_info_ec2_csv.sh where empty fields are now explicitly set to ""
        #s|,$|,\"\"|;

csv="aws_info_all_profiles-$(date '+%F_%H.%M.%S').csv"

# AWS Virtual Machines
cat >&2 <<EOF
# ============================================================================ #
#                      A W S   I n f o   I n v e n t o r y
# ============================================================================ #

Saving to: $PWD/$csv

EOF

aws_foreach_profile.sh "
    '$srcdir/aws_info_csv.sh' '{profile}' |
    sed '
        s|^|\"{profile}\",|;
        1s|^\"{profile}\"|\"AWS_Profile\"|;
    '
" |
tee "$csv"

tmp="$(mktemp)"

sort -fu "$csv" > "$tmp"

mv "$tmp" "$csv"

echo >&2
timestamp "Script Completed Successfully: ${0##*/}"
