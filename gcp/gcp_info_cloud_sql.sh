#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-13 19:38:39 +0100 (Thu, 13 Aug 2020)
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
. "$srcdir/lib/gcp.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Lists GCP Cloud SQL instances and the status of backups for each SQL instance in the current GCP Project

Can optionally specify a project id using the first argument, otherwise uses currently configured project

$gcp_info_formatting_help
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<project_id>]"

help_usage "$@"

check_bin gcloud

if [ $# -gt 0 ]; then
    project_id="$1"
    shift || :
    export CLOUDSDK_CORE_PROJECT="$project_id"
fi


# shellcheck disable=SC1090,SC1091
type is_service_enabled &>/dev/null || . "$srcdir/gcp_service_apis.sh" >/dev/null


# Cloud SQL instances
cat <<EOF
# ============================================================================ #
#                     C l o u d   S Q L   I n s t a n c e s
# ============================================================================ #

EOF

# might need this one instead sqladmin.googleapis.com
if is_service_enabled sql-component.googleapis.com; then
    gcp_info "Cloud SQL instances" gcloud sql instances list
    gcp_info "Cloud SQL backups enabled"   gcloud sql instances list --format="table(name, settings.backupConfiguration.enabled: label='BACKUPS_ENABLED', settings.backupConfiguration.pointInTimeRecoveryEnabled, settings.backupConfiguration.replicationLogArchivingEnabled, settings.backupConfiguration.startTime)"
    echo
    "$srcdir/gcp_info_cloud_sql_databases.sh"
else
    echo "Cloud SQL API (sql-component.googleapis.com) is not enabled, skipping..."
fi
