#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-06-02 17:09:07 +0100 (Wed, 02 Jun 2021)
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
. "$srcdir/lib/gcp.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Creates a GCP service account for Spinnaker deployments in the current or specified GCP project, then
creates and downloads the credentials json and even prints the commands to configure your Spinnaker Halyard CLI:

hal config storage gcs edit --project \$PROJECT --bucket-location \$BUCKET_LOCATION --json-path \$KEYFILE
hal config storage edit --type gcs

hal config artifact gcs account add \$PROJECT --json-path \$KEYFILE
hal config artifact gcs enable


The following optional arguments can be given:

- credential file path          (default: \$HOME/.gcloud/spinnaker-\$project-credential.json)
- project                       (default: \$CLOUDSDK_CORE_PROJECT or gcloud config's currently configured project setting core.project)

Idempotent - safe to re-run, will skip service accounts and keyfiles that already exist
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<credential.json> <project>]"

help_usage "$@"

#min_args 1 "$@"

name="spinnaker"

# XXX: sets the GCP project for the duration of the script for consistency purposes (relying on gcloud config could lead to race conditions)
project="${2:-${CLOUSDK_CORE_PROJECT:-$(gcloud config list --format='get(core.project)')}}"

not_blank "$project" || die "ERROR: no project specified and \$CLOUDSDK_CORE_PROJECT / GCloud SDK config core.project value not set"
export CLOUDSDK_CORE_PROJECT="$project"

keyfile="${1:-$HOME/.gcloud/$name-$project-credential.json}"

gcp_create_serviceaccount_if_not_exists "$name" "$project" "Spinnaker service account for deployments"

service_account="$name@$project.iam.gserviceaccount.com"

gcp_create_credential_if_not_exists "$service_account" "$keyfile"

# XXX: this could probably be limited to just the bucket rather than the entire project, this is how Spinnaker docs do it, so unclear if there are further requirements for this high privileges
echo "Granting Storage Admin permissions to service account '$service_account' on project '$project'"
# some projects may require --condition=None in non-interactive mode
gcloud projects add-iam-policy-binding "$project" --member="serviceAccount:$service_account" --role roles/storage.admin --condition=None >/dev/null

keyfile="$(readlink -e "$keyfile")"

cat <<EOF


You can now continue to configure Spinnaker Halyard CLI with these details:

Needed to store Application settings + Pipelines:

hal config storage gcs edit --project "$project" --bucket-location "\$BUCKET_LOCATION" --json-path "$keyfile"
hal config storage edit --type gcs

Optional - only needed if using artifacts stored on GCS:

hal config artifact gcs account add "$project" --json-path "$keyfile"
hal config artifact gcs enable
EOF
