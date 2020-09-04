#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-13 19:38:39 +0100 (Thu, 13 Aug 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC1090
. "$srcdir/lib/gcp.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Lists GCP Big Data resources deployed in the current GCP Project

Lists in this order:

    - Dataproc clusters       (all regions)
    - Dataproc jobs           (all regions)
    - Dataflow jobs           (all regions)
    - PubSub topics
    - Cloud IOT registries    (all regions)

$gcp_info_formatting_help
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"


# shellcheck disable=SC1090
type is_service_enabled &>/dev/null || . "$srcdir/gcp_service_apis.sh" >/dev/null


# Dataproc clusters
cat <<EOF
# ============================================================================ #
#                       D a t a p r o c   C l u s t e r s
# ============================================================================ #

EOF

if is_service_enabled dataproc.googleapis.com; then
    gcp_info "Dataproc clusters" gcloud dataproc clusters list --region all

    gcp_info "Dataproc jobs"     gcloud dataproc jobs list --region all
else
    echo "Dataproc API (dataproc.googleapis.com) is not enabled, skipping..."
fi


# Dataflow jobs
cat <<EOF


# ============================================================================ #
#                           D a t a f l o w   J o b s
# ============================================================================ #

EOF

# works even when set to disabled:
#
# DISABLED  dataflow.googleapis.com   Dataflow API
#
#if is_service_enabled dataflow.googleapis.com; then
    gcp_info "Dataflow jobs" gcloud dataflow jobs list --region=all
#else
#    echo "Dataflow API (dataflow.googleapis.com) is not enabled, skipping..."
#fi


# PubSub topics
cat <<EOF


# ============================================================================ #
#                           P u b S u b   T o p i c s
# ============================================================================ #

EOF

if is_service_enabled pubsub.googleapis.com; then
    gcp_info "Cloud PubSub topics" gcloud pubsub topics list
else
    echo "Cloud PubSub API (pubsub.googleapis.com) is not enabled, skipping..."
fi


# Cloud IOT
cat <<EOF


# ============================================================================ #
#                               C l o u d   I O T
# ============================================================================ #

EOF

if is_service_enabled cloudiot.googleapis.com; then
    gcp_info "Cloud IOT registries" gcloud iot registries list --region=all
else
    echo "Cloud IOT API ( cloudiot.googleapis.com) is not enabled, skipping..."
fi
