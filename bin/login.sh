#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-06-21 14:51:31 +0100 (Tue, 21 Jun 2022)
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
. "$srcdir/lib/aws.sh"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/gcp.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Runs logins to well known Cloud platforms (AWS, GCP, GitHub, DockerHub etc) if any relevant authentication tokens are found for them in the environment

If targets are given, only runs the logins for those platforms

Currently supports:

- AWS
- GCP
- GitHub CLI
- Docker Registries:
  - DockerHub
  - GitHub Container Registry (GHCR)
  - Gitlab Container Registry
  - AWS Elastic Container Registry (ECR)
  - Azure Container Registry (ACR)
  - Google Container Registry (GCR)
  - Google Artifact Registry (GAR)
  - Quay.io Container Registry (quay)

See Also:

    login.groovy in repo: https://github.com/HariSekhon/Jenkins
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<targets>"

help_usage "$@"

all(){
    dockerhub
    github
    ghcr
    aws
    gcp
    azure
    ecr
    gcr
    gar
    acr
    gitlab
    quay
}

dockerhub(){
    if [ -n "${DOCKERHUB_USER:-}" ] &&
       [ -n "${DOCKERHUB_TOKEN:-}" ]; then
        echo "Logging in to DockerHub:"
        docker login -u "$DOCKERHUB_USER" --password-stdin <<< "$DOCKERHUB_TOKEN"
        echo
    fi
}

github(){
    if [ -n "${GH_TOKEN:-}" ] ||
       [ -n "${GITHUB_TOKEN:-}" ]; then
        echo "GitHub CLI auth:"
        # won't log in if these tokens are set, env overrides CLI
        #if [ -n "${GH_TOKEN:-}" ]; then
        #    gh auth login --with-token <<< "$GH_TOKEN"
        #else
        #    gh auth login --with-token <<< "$GITHUB_TOKEN"
        #fi
        gh auth status
        #echo  # above command already puts a blank line
    fi
}

ghcr(){
    if [ -z "${GITHUB_USER:-}" ]; then
        return
    fi
    echo "Logging in to GitHub Container Registry (GHCR):"
    if [ -n "${GH_TOKEN:-}" ] || [ -n "${GITHUB_TOKEN:-}" ]; then
        docker login ghcr.io -u "$GITHUB_USER" --password-stdin <<< "${GH_TOKEN:-$GITHUB_TOKEN}"
    fi
    echo
}

aws(){
    if [ -n "${AWS_ACCESS_KEY_ID:-}" ] &&
       [ -n "${AWS_SECRET_ACCESS_KEY:-}" ] ||
       grep -Fxq "[${AWS_PROFILE:-nonexistent}]" ~/.aws/credentials 2>/dev/null; then
        echo "AWS CLI auth:"
        command aws sts get-caller-identity
        echo
    fi
}

gcp(){
    if [ -n "${GCP_SERVICEACCOUNT_KEY:-}" ]; then
        export CLOUDSDK_CORE_DISABLE_PROMPTS=1
        echo "Logging in to Google Cloud:"
        #gcloud auth activate-service-account --key-file=<(base64 --decode <<< "$GCP_SERVICEACCOUNT_KEY")
        gcp_login
        echo
    fi
}

azure(){
    if [ -n "${AZURE_USER:-}" ] &&
       [ -n "${AZURE_PASSWORD:-}" ]; then
        echo "Logging in to Azure Cloud:"
        az login -u "$AZURE_USER" -p "$AZURE_PASSWORD"
        echo
        az ad signed-in-user show
        echo
    fi
}

ecr(){
    if [ -z "${AWS_DEFAULT_REGION:-}" ]; then
        AWS_DEFAULT_REGION="$(aws_region)"
    fi
    if ! command aws sts get-caller-identity &>/dev/null; then
        return
    fi
    echo "Logging in to AWS Elastic Container Registry:"
    if [ -z "${AWS_ACCOUNT_ID:-}" ]; then
      local AWS_ACCOUNT_ID
      AWS_ACCOUNT_ID="$(command aws sts get-caller-identity | jq -r .Account)"
      if [ -z "$AWS_ACCOUNT_ID" ]; then
        echo "Failed to determine AWS_ACCOUNT_ID"
        exit 1
      fi
    fi
    local ECR_TOKEN
    ECR_TOKEN="$(command aws ecr get-login-password --region "$AWS_DEFAULT_REGION")"
    if [ -z "$ECR_TOKEN" ]; then
      echo "Failed to get AWS ECR authentication token"
      exit 1
    fi
    docker login "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com" -u AWS --password-stdin <<< "$ECR_TOKEN"
    echo
}

gar(){
    if [ -n "${GAR_REGISTRY:-}" ]; then
        echo "Logging in to Google Artifact Registry:"
        if command -v gcloud &>/dev/null; then
            gcloud auth configure-docker "$GAR_REGISTRY"
        else
            echo "GCloud SDK is not installed, attempting to login with docker directly" >&2
            if [ -z "${GCP_SERVICEACCOUNT_KEY:-}" ]; then
                die "GCP_SERVICEACCOUNT_KEY environment variable not set!"
            fi
            docker login "$GAR_REGISTRY" -u _json_key --password-stdin <<< "$(base64 --decode <<< "$GCP_SERVICEACCOUNT_KEY")"
        fi
        echo
    fi
}

gcr(){
    if [ -n "${GCR_REGISTRY:-}" ]; then
        echo "Logging in to Google Container Registry:"
        if command -v gcloud &>/dev/null; then
            gcloud auth configure-docker "$GCR_REGISTRY"
        else
            echo "GCloud SDK is not installed, attempting to login with docker directly" >&2
            if [ -z "${GCP_SERVICEACCOUNT_KEY:-}" ]; then
                die "GCP_SERVICEACCOUNT_KEY environment variable not set!"
            fi
            docker login "$GCR_REGISTRY" -u _json_key --password-stdin <<< "$(base64 --decode <<< "$GCP_SERVICEACCOUNT_KEY")"
        fi
        echo
    fi
}

acr(){
    if [ -n "${ACR_REGISTRY_NAME:-}" ]; then
        echo "Logging in to Azure Container Registry:"
        #local TOKEN
        #TOKEN="$(az acr credential show --name "$registry_name")"
        az acr login --name "$ACR_REGISTRY_NAME.azurecr.io"
        echo
    fi
}

gitlab(){
    if [ -n "${GITLAB_USER:-}" ] &&
       [ -n "${GITLAB_TOKEN:-}" ]; then
        echo "Logging in to GitLab Container Registry:"
        docker login registry.gitlab.com -u "$GITLAB_USER" --password-stdin <<< "$GITLAB_TOKEN"
        echo
    fi
}

quay(){
    if [ -n "${QUAY_USER:-}" ] &&
       [ -n "${QUAY_TOKEN:-}" ]; then
        echo "Logging in to Quay.io Registry:"
        docker login quay.io -u "$QUAY_USER" --password-stdin <<< "$QUAY_TOKEN"
        echo
    fi
}

if [ -n "$*" ]; then
    shopt -s nocasematch
    for target in "$@"; do
        case "$target" in
            dockerhub)  dockerhub
                        ;;
               github)  github
                        ;;
                 ghcr)  ghcr
                        ;;
                  aws)  aws
                        ;;
                  gcp)  gcp
                        ;;
                azure)  azure
                        ;;
                  ecr)  ecr
                        ;;
                  gcr)  gcr
                        ;;
                  gar)  gar
                        ;;
                  acr)  acr
                        ;;
               gitlab)  gitlab
                        ;;
                 quay)  quay
                        ;;
        esac
    done
else
    all
fi
