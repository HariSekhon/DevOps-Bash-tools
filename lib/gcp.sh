#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  shellcheck disable=SC1090,SC2034
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
gcp_lib_srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$gcp_lib_srcdir/utils.sh"

gcp_info_noninteractive_help="You should only this script non-interactively / in pipes once you have tested it locally on the command line because some services may prompt you for choices, eg. Cloud Run, which you should save to your GCloud SDK config settings first"

gcp_info_formatting_help="In interactive mode, prints fancy boxes around GCP info to be easier on the eye. In non-interactive mode it skips formatting so it's easier to parse or process with other commands like grep / awk etc. Non-interactive mode happens automatically when the output is piped or redirected to a file or another command, or when \$NO_FORMATTING=1 is set in environment"

usage_gcloud_sdk_required="GCloud SDK must be installed and configured"

if is_piped || [ -n "${NO_FORMATTING:-}" ]; then
    gcloud_formatting=''
else
    # want deferred expansion
    # shellcheck disable=SC2016
    gcloud_formatting='"[box,title=\"$title\"]"'
fi

# not anchoring here any more so that we can use these to compose more complex regex - client should anchor regex in matches
gcr_image_regex='([^\.]+\.)?gcr\.io/[^/]+/[^:]+'
gcr_image_tag_regex="$gcr_image_regex:.+"
gcr_image_optional_tag_regex="$gcr_image_regex(:.+)?"

gcp_info(){
    local title="$1"
    shift || :
    if [ -z "$gcloud_formatting" ]; then
        #perl -e "print '=' x (${#title} + 1);"
        for ((i=0; i <= ${#title}; i++)); do
            #printf '='
            # built-in - not as portable eg. sh, but given we explicitly execute in bash should be ok
            echo -n '='
        done
        echo
        echo "$title:"
    fi
    if [[ "$*" =~ --format ]]; then
        # eval formatting for table only to get late evaluated $title
        "${@//--format=table\(/--format=table$(eval echo "$gcloud_formatting")\(}"
    else
        # formatting has to be eval'd in order to pick up latest $title as a late binding
        # better than eval'ing the entire command line to evaluate $title in the formatting string interpolation
        "$@" --format="$(eval echo "$gcloud_formatting")" || return
        if [ -z "$gcloud_formatting" ]; then
            echo
        fi
    fi
}

# avoid race conditions on changing the configuration
# (it's still possible to change the settings within the configuration, use CLOUDSDK_CORE_PROJECT and similar overrides on an as needed basis)
gcloud_export_active_configuration(){
    local active_configuration
    active_configuration="$(gcloud config configurations list --format='get(name)' --filter='is_active = True')"
    export CLOUDSDK_ACTIVE_CONFIG_NAME="$active_configuration"
}

gcp_serviceaccount_exists(){
    local service_account="$1"
    gcloud iam service-accounts list --format='get(email)' --filter="email:$service_account" |
    grep -Fxq "$service_account"
}

gcp_create_serviceaccount_if_not_exists(){
    local name="$1"
    local project="$2"
    local description="${3:-}"
    local service_account="$name@$project.iam.gserviceaccount.com"

    if gcp_serviceaccount_exists "$service_account"; then
        echo "Service account '$service_account' already exists" >&2
    else
        gcloud iam service-accounts create "$name" --description="$description" --project "$project"
    fi
}

gcp_create_credential_if_not_exists(){
    local serviceaccount="$1"
    local keyfile="$2"
    mkdir -pv "$(dirname "$keyfile")"
    if [ -f "$keyfile" ]; then
        echo "Credentials keyfile '$keyfile' already exists" >&2
    else
        gcloud iam service-accounts keys create "$keyfile" --iam-account="$service_account" --key-file-type="json"
    fi
}

# necessary so you can log in to different projects and maintain IAM permissions isolation for safety
# do not use the same serviceaccount with permissions across projects, you can cross contaminate and make mistakes, deploy the wrong environment etc.
gcp_login(){
    local credentials_json="${1:-}"
    if [ -n "$credentials_json" ] &&
       [ -f "$credentials_json" ]; then
        gcloud auth activate-service-account --key-file="$credentials_json"
    elif [ -n "${GCP_SERVICEACCOUNT_KEY:-}" ]; then
        # XXX: it's hard to copy the contents of this around so it's easiest to do via:
        #
        #   base64 credentials.json | pbcopy
        #
        # and then paste that into the CI/CD environment variables for the build
        #
        gcloud auth activate-service-account --key-file=<(base64 --decode <<< "$GCP_SERVICEACCOUNT_KEY")
    else
        die "no credentials.json file passed to gcp_login() and \$GCP_SERVICEACCOUNT_KEY not set in environment"
    fi
}

gke_login(){
    local cluster_name="$1"
    # if running the CI build on the same k8s cluster as the deployment will go to - this is often not the case and not reliable to be detected either since we are often running these builds inside docker images and it would rely on correctly configuring the environment variables to be able to detect this. Instead just open the GKE's cluster's master networks to the projects external NAT IP
    #local opts=(--internal-ip)
    local opts=()
    gcloud container clusters get-credentials "$cluster_name" "${opts[@]}"
}

enable_kaniko(){
    #gcloud config set builds/use_kaniko True
    export CLOUDSDK_BUILDS_USE_KANIKO=True
}
