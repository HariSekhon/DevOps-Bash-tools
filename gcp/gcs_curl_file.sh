#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-02-16 01:11:31 +0000 (Fri, 16 Feb 2024)
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
Retrieves a GCS file's contents from a given bucket and path using GCP authentication to the Storage JSON API

Useful for starting shell pipelines or being called from other scripts such as terraform_gcs_backend_version.sh

Requires GCloud SDK and jq being installed as well as GCloud SDK being already authenticated with an account with permission to the bucket
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<bucket> <file_path>"

help_usage "$@"

num_args 2 "$@"

bucket="$1"
filepath="$2"
# there should be no leading slash - that would lead to a Not Found error
filepath="${2##/}"
# must urlencode /paths/to/file
filepath="$("$srcdir/../bin/urlencode.sh" <<< "$filepath")"
# alternatives
# from DevOps-Python-tools repo if in $PATH
#filepath="$(urlencode.py <<< "$filepath")"
# from DevOps-Perl-tools repo if in $PATH
#filepath="$(urlencode.pl <<< "$filepath")"

access_token="$(gcloud auth print-access-token || die "Failed to get GCP access token - you must be authenticated first")"

export CURL_OPTS='-sS'
export TOKEN="$access_token"

"$srcdir/../bin/curl_auth.sh" $CURL_OPTS "https://storage.googleapis.com/storage/v1/b/$bucket/o/$filepath?alt=media"
