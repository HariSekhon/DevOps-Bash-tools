#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-12-19 11:21:30 +0000 (Thu, 19 Dec 2019)
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
Prints users access keys and their last used date

Output format, tab separated:

<user>    <access_key>   <last_used_date>  <region>


See Also:

    aws_iam_users_access_key_last_used.sh - much quicker version for lots of users


See similar tools in DevOps Python Tools repo:

    https://github.com/HariSekhon/DevOps-Python-tools


$usage_aws_cli_jq_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

export AWS_DEFAULT_OUTPUT=json

if [ $# -gt 0 ]; then
    users="$*"
else
    echo "output will be formatted in to columns at end" >&2
    echo "getting user list" >&2
    users="$(aws iam list-users | jq -r '.Users[].UserName')"
fi

while read -r username; do
    echo "querying user $username" >&2
    aws iam list-access-keys --user-name "$username" |
    jq -r '.AccessKeyMetadata[].AccessKeyId' |
    while read -r access_key; do
        aws iam get-access-key-last-used --access-key-id "$access_key" |
        jq -r '[.UserName, .AccessKeyLastUsed.LastUsedDate, .AccessKeyLastUsed.Region] | @tsv' |
#        while read -r user last_used region; do
#            # if there is no last_used field, 3rd field will be taken from region
#            #if [ -z "$region" ]; then
#            #    region="$last_used"
#            #    last_used="blank"
#            #fi
#            if [ -z "$region" ] && [ "$last_used" = "N/A" ]; then
#                region="N/A"
#            fi
#            printf '%s\t%s\t%s\t%s\n' "$user" "$access_key" "${last_used:-blank}" "$region"
#        done
        awk '{if(NF==2){$3="N/A"}; print $1"\t'"$access_key"'\t"$2"\t"$3}'
    done
done <<< "$users" |
column -t
