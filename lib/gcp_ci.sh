#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-03-02 18:59:07 +0000 (Tue, 02 Mar 2021)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# ============================================================================ #
#                    G C P   C I   S h a r e d   L i b a r y
# ============================================================================ #
set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "${BASH_SOURCE[0]}")"

# shellcheck disable=SC1090
. "$srcdir/gcp.sh"

# ============================================================================ #
#       J e n k i n s   /   T e a m C i t y   B r a n c h   +   B u i l d
# ============================================================================ #

# Jenkins provides $BRANCH_NAME only in MultiBranch builds, otherwise use $GIT_BRANCH
# TeamCity doesn't provide this so will fall back to git rev-parse
if [ -z "${BRANCH_NAME:-}" ]; then
    BRANCH_NAME="${GIT_BRANCH:-$(git rev-parse --abbrev-ref HEAD)}"
fi
BRANCH_NAME="${BRANCH_NAME##*/}"

# Jenkins provides $GIT_COMMIT, TeamCity provides $BUILD_VCS_NUMBER
BUILD="${GIT_COMMIT:-${BUILD_VCS_NUMBER:-$(git show-ref --hash HEAD)}}"

# ============================================================================ #
#                    G C P   P r o j e c t   +   R e g i o n
# ============================================================================ #

# If Project isn't set in the CI/CD environment (safest way as it doesn't have a race condition with global on-disk gcloud config), then infer it
set_gcp_project(){
    # in Jenkins the branch is prefixed with origin/
    if [ -z "${CLOUDSDK_CORE_PROJECT:-}" ]; then
        if [[ "$BRANCH_NAME" =~ ^(dev|staging)$ ]]; then
            export CLOUDSDK_CORE_PROJECT="$MYPROJECT-$BRANCH_NAME"
        elif [ "$BRANCH_NAME" = production ]; then
            # production project has a non-uniform project id, so override it
            export CLOUDSDK_CORE_PROJECT="$MYPROJECT-prod"
        else
            # assume it is a feature branch being deployed to the Dev project
            export CLOUDSDK_CORE_PROJECT="$MYPROJECT-dev"
        fi
    fi
}

set_gcp_compute_region(){
    local region="${1:-europe-west1}"
    if [ -z "${CLOUDSDK_COMPUTE_REGION:-}" ]; then
        # Set default region where you GKE cluster is going to be
        export CLOUDSDK_COMPUTE_REGION="$region"
        # Do an override if you have a project that is in a different region to the rest
    #    if [ "$CLOUDSDK_CORE_PROJECT" = "$MYPROJECT-staging" ]; then
    #        # Staging's location is different
    #        export CLOUDSDK_COMPUTE_REGION="europe-west4"
    #    fi
    fi
}

# ============================================================================ #
#           Print the Environment in every build for easier debugging
# ============================================================================ #

printenv(){
    echo "Environment:"
    env | sort
}

# ============================================================================ #
#                               F u n c t i o n s
# ============================================================================ #

list_container_tags(){
    local image="$1"
    local build="$2"  # Git hashref that triggered CI build
    # --format=text returns blank if no match tag for the docker image exists, which is convenient for testing such tags_exist_for_container_image() below
    gcloud container images list-tags --filter="tags:${build}" --format=text "gcr.io/$CLOUDSDK_CORE_PROJECT/$image"
    # will get this error if you try running this is via DooD, switching to normal K8s pod template in pipeline solves this:
    # ERROR: gcloud crashed (MetadataServerException): HTTP Error 404: Not Found
}

tags_exist_for_container_image(){
    # since list_container_tags returns blank if this build hashref doesn't exist, we can use this as a simple test
    [ -n "$(list_container_tags "$APP" "$BUILD")" ]
}

gcloud_builds_submit(){
    local build="$1"
    local cloudbuild_yaml="${2:-cloudbuild.yaml}"
    gcloud builds submit --project "$CLOUDSDK_CORE_PROJECT" --config "$cloudbuild_yaml" --substitutions _REGISTRY="gcr.io/$CLOUDSDK_CORE_PROJECT,_BUILD=$build" --timeout=3600
    # will get this error if you try running this is via DooD, switching to normal K8s pod template in pipeline solves this:
    # ERROR: gcloud crashed (MetadataServerException): HTTP Error 404: Not Found
}

# yamls contain tag 'latest', we replace this with the build hashref matching the docker images just built as part of the build pipeline
# Better is to use CI/CD to update the kustomization.yaml with the hashref as part of a GitOps workflow - see my Jenkins shared library https://github.com/HariSekhon/Jenkins/tree/master/vars
replace_latest_with_build(){
    local build="$1"
    sed -i "s/\\([[:space:]]newTag:[[:space:]]*\"*\\)latest/\\1$build/g" -- kustomization.yaml
    sed -i "s/commit=latest/commit=$build/g" -- kustomization.yaml
}

download_kustomize(){
    #curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash
    # better to fix version in case later versions change behaviour or syntax
    curl -o kustomize --location https://github.com/kubernetes-sigs/kustomize/releases/download/v3.1.0/kustomize_3.1.0_linux_amd64
    chmod u+x ./kustomize
}

kubernetes_deploy(){
    local app="$1"
    local namespace="$2"
    kubectl apply -f .
    kubectl rollout status "deployment/$app" -n "$namespace" --timeout=120s
}

# old, use ArgoCD instead now, see Kubernetes repo:
#
#   https://github.com/HariSekhon/Kubernetes-configs
#
kustomize_kubernetes_deploy(){
    local app="$1"
    local namespace="$2"
    # append to PATH to be able to find just downloaded ./kustomize
    PATH="$PATH:." kubectl_create_namespaces.sh
    # XXX: DANGER: this would replace $RABBITMQ_HOME - needs more testing to support 'feature staging' / 'feature dev' - but envsubst doesn't support default values
    #PATH="$PATH:." kustomize build . | envsubst | kubectl apply -f -
    PATH="$PATH:." kustomize build . | kubectl apply -f -
    kubectl annotate "deployment/$app" -n "$namespace" kubernetes.io/change-cause="$(date '+%F %H:%M')  CI deployment: app $app build ${BUILD:-}"
    local deployments
    deployments="$(kubectl get deploy,sts -n "$namespace" --output name)"
    # $deployment contains deployment.apps/ or statefulset.apps/ prefixes
    trap 'echo "ERROR: kubernetes $namespace $deployment is BROKEN - possible misconfiguration or bad code is preventing pods from coming up after a reasonable timeframe of retries, please see GKE container logs" >&2' EXIT
    # using a global shared timeout rather than a --timeout="${timeout}s" for each kubectl rollout as that multiplies by the amount of deployments and statefulsets which should have been working
    TMOUT=600
    for deployment in $deployments; do
        kubectl rollout status "$deployment" -n "$namespace"
    done
    trap '' EXIT

    # could also run the deployment via Google Cloud Build
    #gcloud builds submit --project "$CLOUDSDK_CORE_PROJECT" --config="../../cloudbuild-deploy.yaml" --no-source
}
