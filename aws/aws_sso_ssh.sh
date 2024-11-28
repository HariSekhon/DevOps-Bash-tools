#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-11-28 20:19:46 +0700 (Thu, 28 Nov 2024)
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
Launches local AWS SSO authentication pop-up (if not already authenticated)

Then scp's the latest resultant ~/.aws/sso/cache/ file to the remote server

And SSH's there so that you can use AWS CLI or kubectl to EKS remotely on that server easily,
without having to copy and paste the token from remote aws sso login to your local web browser

Useful in enviroments where only a bastion server can access EKS clusters or other AWS services

Best used when combined with automatically configuring your environment variables for the AWS_PROFILE etc.
using direnv or similar

For code on how to do that, see:

    https://github.com/HariSekhon/Environments


Requires AWS CLI to be installed and configured
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[user@]server [<aws_sso_options>]"

help_usage "$@"

min_args 1 "$@"

server="$1"
shift || :

timestamp "Checking if AWS SSO is already logged in"
if is_aws_sso_logged_in; then
    timestamp "Already authenticated to AWS SSO, skipping login for speed"
else
    timestamp "Not currently authenticated to AWS SSO, launching login:"
    echo >&2
    aws sso login "$@"
    echo >&2
fi

# in case HOME isn't set
[ -n "${HOME:-}" ] || HOME=~

# AWS SSO uses ~/.aws/sso/cache/ not old credentials file
#creds="${AWS_SHARED_CREDENTIALS_FILE:-$HOME/.aws/credentials}"

# shellcheck disable=SC2012
creds="$(ls -t ~/.aws/sso/cache/* | head -n1)"

timestamp "Latest AWS SSO cache file found is: $creds"

if is_mac; then
    mod_time="$(stat -f %m "$creds")"
else  # Linux
    mod_time="$(stat -c %Y "$creds")"
fi

current_time="$(date +%s)"

seconds_ago="$((current_time - mod_time))"

if [ "$seconds_ago" -gt 86400 ]; then
    warn "AWS credentials file '$creds' was last modified '$seconds_ago' seconds ago, not within the last 86400 seconds"
    warn "(1 day - the max lifetime of an AWS SSO login cache)"
    warn "ERROR: Not copying credentials file remotely for overwrite safety in case we have the wrong file"
    exit 1
fi

# shellcheck disable=SC2295
creds_without_home="${creds#$HOME}"
creds_without_home="${creds_without_home##/}"

scp "$creds" "$server":"$creds_without_home"

echo >&2

exec ssh "$server"
