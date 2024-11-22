#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: echo 'AWS_PROFILE=$AWS_PROFILE, {profile\}={profile}'
#
#  Author: Hari Sekhon
#  Date: 2021-07-28 16:28:01 +0100 (Wed, 28 Jul 2021)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
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
Run a command against each AWS named profile configured for the local AWS CLIv2

This is powerful so use carefully!

WARNING: do not run any command reading from standard input, otherwise it will consume the profile names and exit after the first iteration

Requires AWS CLIv2 to be installed and configured (older AWS CLIv1 that is installed via pip doesn't support this)

All arguments become the command template

AWS_PROFILE is set in each iteration and {profile} is replaced in any commands


eg.
    ${0##*/} echo 'AWS_PROFILE=\$AWS_PROFILE, {profile\\}={profile}'

To set up your Kubernetes access to all clusters in all locally configured accounts using adjacent aws_kube_creds.sh script

    ${0##*/} aws_kube_creds.sh
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<command> <args>"

help_usage "$@"

min_args 1 "$@"

profiles="$(aws configure list-profiles --output text)"

total_profiles="$(wc -l <<< "$profiles" | sed 's/[[:space:]]//g')"

i=0

while read -r profile; do
    (( i += 1 ))
    echo "# ============================================================================ #" >&2
    echo "# ($i/$total_profiles) AWS profile = $profile" >&2
    echo "# ============================================================================ #" >&2
    export AWS_PROFILE="$profile"
    cmd=("$@")
    cmd=("${cmd[@]//\{profile\}/$profile}")
    # need eval'ing to able to inline quoted script
    # shellcheck disable=SC2294
    eval "${cmd[@]}"
    echo >&2
    echo >&2
done <<< "$profiles"
