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
Lists GCP Projects and checks project is configured

Can optionally specify a project id to switch to (will switch back to original project on any exit except kill -9)

Can optionally specify a project id using the first argument, otherwise uses currently configured project

$gcp_info_formatting_help
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<project_id>]"

help_usage "$@"

max_args 1 "$@"

check_bin gcloud

if [ $# -gt 0 ]; then
    project_id="$1"
    shift || :
    export CLOUDSDK_CORE_PROJECT="$project_id"
fi


# Project
cat <<EOF
# ============================================================================ #
#                                P r o j e c t s
# ============================================================================ #

EOF

gcp_info "GCP Projects" gcloud projects list
echo
echo "Checking project is configured..."
# unreliable only errors when not initially set, but gives (unset) if you were to 'gcloud config unset project'
#if ! gcloud config get-value project &>/dev/null; then
# ok, but ugly and format dependent
#if ! gcloud config list | grep '^project[[:space:]]='; then
# best
if ! gcloud info --format="get(config.project)" | grep -q .; then
    cat <<EOF

ERROR: You need to configure your Google Cloud project first

Select one from the project IDs above:

gcloud config set project <id>
EOF
    exit 1
fi
