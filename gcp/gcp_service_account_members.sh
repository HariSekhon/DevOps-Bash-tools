#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-04-22 16:34:20 +0100 (Thu, 22 Apr 2021)
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

# shellcheck disable=SC2034,SC2154
usage_description="
Lists one or all GCP service accounts with their members and roles

Useful for finding which users have ability to impersonate a service account and more importantly for GKE Workload Identity mappings

Service accounts must be given by email as standard, eg:

    <name>@<project>.iam.gserviceaccount.com

Output:

    <service_account_email>     <member>      <role>

eg.

<name>@<project>.iam.gserviceaccount.com  serviceAccount:jenkins@<project>.iam.gserviceaccount.com    roles/iam.serviceAccountUser
<name>@<project>.iam.gserviceaccount.com  serviceAccount:<project>.svc.id.goog[k8s_namespace/k8s_sa]  roles/iam.workloadIdentityUser
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<service_account_email1> <service_account_email2>]"

help_usage "$@"

max_args 1 "$@"

if [ $# -gt 0 ]; then
    tr ' ' '\n' <<< "$@"
else
    gcloud iam service-accounts list --format='get(email)'
fi |
while read -r service_account_email; do
    gcloud iam service-accounts get-iam-policy "$service_account_email" --format=json |
    jq -r ".bindings[]? | [ \"$service_account_email\", .members[]?, .role] | @tsv"
done #|
# tidier but delays output - can pipe to this column yourself if you want this trade off
#column -t
