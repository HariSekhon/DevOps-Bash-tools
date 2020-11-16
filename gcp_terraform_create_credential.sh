#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-10-28 17:02:13 +0000 (Wed, 28 Oct 2020)
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
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Creates a GCP service account for Terraform deployments in the current or specified GCP project, then
creates and downloads the credentials json and even prints the command to configure your environment to start using Terraform immediately:

export GOOGLE_CREDENTIALS=\$HOME/.gcloud/\$name-\$project-credential.json

The following optional arguments can be given:

- service account name prefix   (default: \$USER-terraform)
- credential file path          (default: \$HOME/.gcloud/\$name-\$project-credential.json)
- project                       (default: gcloud config's currently configured project setting core.project)

Idempotent - safe to re-run, will skip service accounts and keyfiles that already exist
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<name> <credential.json> <project>]"

help_usage "$@"

#min_args 1 "$@"

name="${1:-$USER-terraform}"

project="${3:-$(gcloud config list --format='get(core.project)')}"

# XXX: fix the GCP project for the duration of the script for consistency
not_blank "$project" || die "ERROR: no project specified and GCloud SDK core.project value not set"
export CLOUDSDK_CORE_PROJECT="$project"

keyfile="${2:-$HOME/.gcloud/$name-$project-credential.json}"

service_account="$name@$project.iam.gserviceaccount.com"

if gcloud iam service-accounts list --format='get(email)' | grep -Fxq "$service_account"; then
    echo "Service account '$service_account' already exists"
else
    gcloud iam service-accounts create "$name" --description="$USER's service account for Terraform deployments" --project "$project"
fi

mkdir -pv "$(dirname "$keyfile")"

if [ -f "$keyfile" ]; then
    echo "Credentials keyfile '$keyfile' already exists"
else
    gcloud iam service-accounts keys create "$keyfile" --iam-account="$service_account" --key-file-type="json"
fi

echo "Granting Owner permissions to service account '$service_account' on project '$project'"
# some projects may require --condition=None in non-interactive mode
gcloud projects add-iam-policy-binding "$project" --member="serviceAccount:$service_account" --role=roles/owner --condition=None >/dev/null

if is_mac; then
    readlink(){
        command greadlink "$@"
    }
fi

keyfile="$(readlink -e "$keyfile")"

echo
echo "Set this in your environment to use Terraform now:"
echo
echo "export GOOGLE_CREDENTIALS=$keyfile"
echo
