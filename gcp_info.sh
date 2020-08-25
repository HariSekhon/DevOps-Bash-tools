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

# Gather common GCP environment info for quickly surveying new client environments
#
# Requires:
#
# - GCloud CLI to be available and configured 'gcloud init'
#   (or just use Cloud Shell, will prompt you to set the project if it's not already)
# - API services to be enabled (or to select Y to enable them when prompted)
# - Billing to be enabled in order to enable API services
#
# Tested with Google Cloud SDK installed locally

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Lists GCP deployed resources in the current or specified GCP Project

Will temporarily switch the core.project setting (sets back to previous on exit or any error)
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<project_id>]"

help_usage "$@"

#min_args 1 "$@"

check_bin gcloud

if [ $# -gt 0 ]; then
    project_id="$1"
    shift || :
    current_project="$(gcloud config list --format="value(core.project)")"
    if [ -n "$current_project" ]; then
        # want interpolation now not at exit
        # shellcheck disable=SC2064
        trap "gcloud config set project '$current_project'" EXIT
    else
        trap "gcloud config unset project" EXIT
    fi
    gcloud config set project "$project_id"
fi


cat <<EOF
# ============================================================================ #
#                                  G C l o u d
# ============================================================================ #

EOF

gcloud version

echo

#gsutil version -l

#echo

#bq version


cat <<EOF

# ============================================================================ #
#                           A u t h   &   C o n f i g
# ============================================================================ #

EOF

gcloud config configurations list
echo

# list credentialed accounts and show which one is active - dupliates info from configurations so not needed
#gcloud auth list
#echo

gcloud config list

cat <<EOF


# ============================================================================ #
#                                 P r o j e c t
# ============================================================================ #

EOF

echo "Checking project is configured..."
# unreliable only errors when not initially set, but gives (unset) if you were to 'gcloud config unset project'
#if ! gcloud config get-value project &>/dev/null; then
# ok, but ugly and format dependent
#if ! gcloud config list | grep '^project[[:space:]]='; then
# best
if ! gcloud info --format="get(config.project)" | grep -q .; then
    cat <<EOF

ERROR: You need to set the Google Cloud project first

Select from one of the following projects IDs:

EOF
    gcloud projects list
    cat <<EOF

gcloud config set project <id>
EOF
    exit 1
fi

cat <<EOF

LISTING INFO FOR PROJECT:  $(gcloud info --format="get(config.project)")


# ============================================================================ #
#                                S e r v i c e s
# ============================================================================ #

EOF

echo "Services Enabled:"
echo
gcloud services list --enabled


cat <<EOF


# ============================================================================ #
#                        V i r t u a l   M a c h i n e s
# ============================================================================ #

EOF

#gcloud compute machine-types list

gcloud compute instances list --sort-by=ZONE


cat <<EOF


# ============================================================================ #
#                              N e t w o r k i n g
# ============================================================================ #

EOF

echo "Networks:"
gcloud compute networks list
echo
echo "Addresses:"
gcloud compute addresses list
echo
echo "Subnets:"
gcloud compute networks subnets list --sort-by=NETWORK



cat <<EOF


# ============================================================================ #
#                               F i r e w a l l s
# ============================================================================ #

EOF

gcloud compute firewall-rules list
# same output
#gcloud compute firewall-rules list --sort-by=NETWORK
echo
echo "Forwarding Rules"
gcloud compute forwarding-rules list


cat <<EOF


# ============================================================================ #
#                                 B u c k e t s
# ============================================================================ #

EOF

gsutil ls


cat <<EOF


# ============================================================================ #
#                            G K E   C l u s t e r s
# ============================================================================ #

EOF

gcloud container clusters list


cat <<EOF

# ============================================================================ #
#                                G K E   P o d s
# ============================================================================ #
EOF

while read -r cluster zone; do
    cat <<EOF

# ======================================================= #
# GKE Cluster: $cluster
# ======================================================= #

EOF
    gcloud container clusters get-credentials "$cluster" --zone "$zone"
    echo
    kubectl get pods --all-namespaces
done < <(gcloud container clusters list --format='value(name,zone)')

cat <<EOF

# ============================================================================ #
# Finished listing resources for GCP Project $(gcloud config list --format="value(core.project)")
# ============================================================================ #

EOF
