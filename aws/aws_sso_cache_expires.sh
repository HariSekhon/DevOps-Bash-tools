#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-02-01 00:30:52 +0700 (Sat, 01 Feb 2025)
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
. "$srcdir/lib/aws.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Finds when the recent AWS SSO cache expires


$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

num_args 0 "$@"

# shellcheck disable=SC2012
creds="$(ls -t ~/.aws/sso/cache/* 2>/dev/null | head -n1)"

log "Latest AWS SSO cache file found is: $creds"

# in case HOME isn't set
[ -n "${HOME:-}" ] || HOME=~

if is_mac; then
    mod_time="$(stat -f %m "$creds")"
else  # Linux
    mod_time="$(stat -c %Y "$creds")"
fi

current_time="$(date +%s)"

seconds_ago="$((current_time - mod_time))"

if [ "$seconds_ago" -gt 86400 ]; then
    echo "AWS SSO cache expired, $seconds_ago old"
    exit 1
fi

log "Checking if AWS SSO is already logged in"
if ! is_aws_sso_logged_in; then
    echo "AWS SSO cache expired"
else
    #jq -r '.expiresAt' "$creds"
    #
    # There is a weird situation where the newest file cache is expired earlier today
    #
    # but I have another older one with a timestamp far in the future (more than the usual 1 day of AWS CLI)
    #
    # and the AWS CLI is still working, so this is more accurate than the above which shows the
    #
    # expired cache from earlier today which is clearly not taking precedence
    #
    #   2025-01-31T16:53:34Z
    #   2025-04-09T10:08:04Z
    #
    # this is more accurate in this weird situation
    jq -r '.expiresAt' ~/.aws/sso/cache/*.json | sort -r | head -n1
fi
