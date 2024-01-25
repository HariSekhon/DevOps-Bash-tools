#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-03-02 18:58:29 +0000 (Tue, 02 Mar 2021)
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
. "$srcdir/lib/gcp_ci.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Runs a GCP CI Build using Google Cloud Build

Environment variables to set in the CI/CD system:

APP                     - name of the app / docker image to build
BUILD                   - should be automatically set to the Git hash on Jenkins or TeamCity
CLOUDSDK_CORE_PROJECT   - project ID of your GCP project
GCP_SERVICEACCOUNT_KEY  - the contents of a credentials.json for a serviceaccount with permissions to GCR + GKE

Primarily written for Jenkins and TeamCity, but should work with minor alterations in other CI/CD tools (see lib/gcp_ci.sh which infers branch and build details)
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

# CLOUDSDK_CORE_PROJECT and APP should be set by the CI/CD system
# BUILD is inferred from the Git commit that triggered the CI/CD system
check_env_defined "APP"
check_env_defined "BUILD"
check_env_defined "CLOUDSDK_CORE_PROJECT"
check_env_defined "GCP_SERVICEACCOUNT_KEY"

help_usage "$@"

#min_args 1 "$@"

set -x

printenv

# if you project has a uniform naming that maps to branches, enable and tune this function from lib/gcp_ci.sh
#set_gcp_project

# provide a credentials.json file argument to this function or provide if in a GCP_SERVICEACCOUNT_KEY environment variable via the CI/CD system
# necessary so you can log in to different projects and maintain IAM permissions isolation for safety
# do not use the same serviceaccount with permissions across projects, you can cross contaminate and make mistakes, deploy the wrong environment etc.
gcp_login

# if it's not already built, submit a Google Cloud Build to build the docker images
if ! tags_exist_for_container_image "$APP"; then
    # $BUILD is auto-populated via lib/gcp_ci.sh from GIT_COMMIT in Jenkins or BUILD_VCS_NUMBER in TeamCity
    #gcloud_builds_submit "${BUILD}"

    gcloud builds submit --project "$CLOUDSDK_CORE_PROJECT" --config "cloudbuild.yaml" --substitutions _REGISTRY="gcr.io/$CLOUDSDK_CORE_PROJECT,_BUILD=$BUILD" --timeout=3600

    "$srcdir/gcr_tag_datetime.sh" "$CLOUDSDK_CORE_PROJECT/$APP:$BUILD"
    "$srcdir/gcr_tag_latest.sh"   "$CLOUDSDK_CORE_PROJECT/$APP:$BUILD"
fi
