#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-02-16 01:28:12 +0000 (Fri, 16 Feb 2024)
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
Determines the Terraform state version from the tfstate file in a GCS bucket found in a local given backend.tf

Parses backend.tf for the bucket and file path to the tfstate file in GCS

Then curls that GCS file's contents and parses it to get the state version

This is important so that you know what terraform version to set without accidentally updating the client's terraform state, which can potentially break existing clients and CI/CD which will no longer be able to run using the older client version
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<backend.tf>"

help_usage "$@"

max_args 1 "$@"

backend_tf_file="${1:-$PWD/backend.tf}"

if ! [ -f "$backend_tf_file" ]; then
    die "File not found: $backend_tf_file - check you are specifying the right path to the .tf file containing the backend definition"
fi

log "Parsing $backend_tf_file for bucket and prefix"
# TODO: check if backend "gcs" vs other clouds and extend this to AWS and Azure backends
bucket="$(grep -m1 '^[[:space:]]*bucket[[:space:]]*=.*' "$backend_tf_file" | sed 's/.*=//; s/[[:space:]]//g; s/"//g' || die "Failed to parse bucket from $backend_tf_file")"
prefix="$(grep -m1 '^[[:space:]]*prefix[[:space:]]*=.*' "$backend_tf_file" | sed 's/.*=//; s/[[:space:]]//g; s/"//g' || :)" # || die "Failed to parse bucket from $backend_tf_file")"

log "Fetching and parsing bucket '$bucket' file '$prefix${prefix+/}default.tfstate'"
"$srcdir/../gcp/gcs_curl_file.sh" "$bucket" "$prefix${prefix+/}default.tfstate" |
jq -r '.terraform_version'
