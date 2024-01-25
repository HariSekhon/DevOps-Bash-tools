#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: /health | jq .
#
#  Author: Hari Sekhon
#  Date: 2022-09-14 11:35:49 +0100 (Wed, 14 Sep 2022)
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

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/git.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Queries the GitGuardian.com API

Automatically handles authentication via environment variable \$GITGUARDIAN_TOKEN

Can specify \$CURL_OPTS for options to pass to curl or provide them as arguments


Set up a personal access token here - where nnnnnn is your personal account number seen in your dashboard URLs

    https://dashboard.gitguardian.com/workspace/nnnnnn/api/personal-access-tokens


API Reference:

    https://api.gitguardian.com/docs


Examples:


    # Get health (check API key is valid):

        ${0##*/} /health | jq .

    # Lists Secret Incidents:

        ${0##*/} /incidents/secrets | jq .

    # Get Specific Secret Incident:

        ${0##*/} /incidents/secrets/{incident_id} | jq .

    # List Secret Occurrences:

        ${0##*/} /occurrences/secrets | jq .

    # List Sources - repos and their open incidence counts, last scanned date, health (safe/at_risk), visibility (public/private), type (eg. github):

        ${0##*/} /sources | jq .

    # List Members:

        ${0##*/} /members | jq .

    # List Invitations:

        ${0##*/} /invitations | jq .
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="/path [<curl_options>]"

url_base="https://api.gitguardian.com/v1"

help_usage "$@"

min_args 1 "$@"

curl_api_opts "$@"

url_path="$1"
shift || :

url_path="${url_path//https:\/\/api.gitguardian.com/v1}"
url_path="${url_path##/}"

check_env_defined GITGUARDIAN_TOKEN

export TOKEN="$GITGUARDIAN_TOKEN"

export CURL_AUTH_HEADER="Authorization: Token"

"$srcdir/../bin/curl_auth.sh" "$url_base/$url_path" ${CURL_OPTS:+"${CURL_OPTS[@]}"} "$@" |
jq_debug_pipe_dump
