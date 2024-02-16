#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-02-16 01:00:11 +0000 (Fri, 16 Feb 2024)
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
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Queries the GCP Storage JSON API to find which GCP Project a given GCS bucket belongs to

Output:

<project_id>    <project_name>

Requires GCloud SDK and jq to be installed as well as GCloud SDK being already authenticated with an account with permission to storage.buckets.get and resourcemanager.projects.get in the project where the bucket lives (use a GCP owner account which has access to all your projects)
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<bucket_name>"

help_usage "$@"

num_args 1 "$@"

bucket="$1"

access_token="$(gcloud auth print-access-token || die "Failed to get GCP access token - you must be authenticated first")"

export CURL_OPTS='-sS'
export TOKEN="$access_token"

# https://cloud.google.com/storage/docs/json_api/v1/buckets/get
project_number="$(
    "$srcdir/../bin/curl_auth.sh" $CURL_OPTS "https://storage.googleapis.com/storage/v1/b/$bucket" |
    jq -r '.projectNumber'
)"

gcloud projects list --filter="PROJECT_NUMBER=$project_number" --format="value(PROJECT_ID, NAME)"
