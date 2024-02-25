#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-02-23 17:50:33 +0000 (Fri, 23 Feb 2024)
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
Creates an Ansible service account for the Ansible GCP playbook inventory plugin, in the current or specified GCP
project, then creates and downloads the credentials json and even prints the command to configure your environment
to start using Ansible immediately

export GOOGLE_CREDENTIALS=\$HOME/.gcloud/\$name-\$project-credential.json

The following optional arguments can be given:

- service account name prefix   (default: \$USER-ansible)
- credential file path          (default: \$HOME/.gcloud/\$name-\$project-credential.json)
- project                       (default: \$CLOUDSDK_CORE_PROJECT or gcloud config's currently configured project setting core.project)

Idempotent - safe to re-run, will skip service accounts and keyfiles that already exist
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<name> <credential.json> <project>]"

help_usage "$@"

#min_args 1 "$@"

name="${1:-$USER-ansible}"

# XXX: sets the GCP project for the duration of the script for consistency purposes (relying on gcloud config could lead to race conditions)
project="${3:-${CLOUDSDK_CORE_PROJECT:-$(gcloud config list --format='get(core.project)')}}"

not_blank "$project" || die "ERROR: no project specified and \$CLOUDSDK_CORE_PROJECT / GCloud SDK config core.project value not set"
export CLOUDSDK_CORE_PROJECT="$project"

keyfile="${2:-$HOME/.gcloud/$name-$project-credential.json}"

gcp_create_serviceaccount_if_not_exists "$name" "$project" "$USER's service account for Ansible deployments"

service_account="$name@$project.iam.gserviceaccount.com"

gcp_create_credential_if_not_exists "$service_account" "$keyfile"

echo "Granting Owner permissions to service account '$service_account' on project '$project'"
# some projects may require --condition=None in non-interactive mode
gcloud projects add-iam-policy-binding "$project" --member="serviceAccount:$service_account" --role=roles/owner --condition=None >/dev/null

keyfile="$(readlink -e "$keyfile")"

# https://docs.ansible.com/ansible/latest/collections/google/cloud/gcp_compute_inventory.html
#
#   either
#
#       GCE_CREDENTIALS_FILE_PATH
#   or
#       GCP_SERVICE_ACCOUNT_FILE
#
#   optional
#
#       GCP_SERVICE_ACCOUNT_FILE
echo
echo "Set this in your environment to use Ansible now:"
echo
echo "export GCE_CREDENTIALS_FILE_PATH=$keyfile"
echo
