#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-12-03 16:59:48 +0000 (Fri, 03 Dec 2021)
#
#  https://github.com/HariSekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "${BASH_SOURCE[0]}")"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Prints AWS credentials from a CSV file as shell export statements


Useful to quickly switch your shell to some exported credentials from a service account for testing access / permissions


Example:

    eval \$(${0##*/} new_user_credentials.csv)
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="credential.csv"

help_usage "$@"

min_args 1 "$@"

csv="$1"

if ! [ -f "$csv" ]; then
    die "File not found: $csv"
fi

# access keys are prefixed with AKIA, skips header row
awk -F, '/AKIA/{
    print "export AWS_ACCESS_KEY_ID="$3
    print "export AWS_SECRET_ACCESS_KEY="$4
}' "$csv"
