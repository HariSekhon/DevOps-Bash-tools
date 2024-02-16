#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-02-16 10:55:55 +0000 (Fri, 16 Feb 2024)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
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

backend_variables="
TERRAFORM_BACKEND
TF_BACKEND
TFENV
"

# shellcheck disable=SC2034,SC2154
usage_description="
Fetches the GitLab CI/CD environment variable containing the backend.tf configuration to the local backend.tf so you can do terraform plans locally

For companies that don't store their backend.tf in Git but instead materialized it inside the CI/CD system from an environment variable

This allows to get quickly set up with the right backend.tf locally to do quicker iterations

If variable is not specified defaults to searching for these variables in this order: $(tr '\n' ' ' <<< "$backend_variables")
If environment is not specified defaults to searching for 'dev' or 'development'

Requires GitLab CLI to be installed and authenticated to list and fetch the backend environment variable, and should be executed from within the current terraform project folder so it defaults to the right GitLab project repo
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<variable> <environment_or_scope>]"

help_usage "$@"

max_args 2 "$@"

backend_tf_file="$PWD/backend.tf"

variable="${1:-}"
environment="${2:-}"

timestamp "Getting GitLab CI/CD variables"
variables="$(glab variable list 2>&1)"

if [ -z "$variable" ]; then
    for possible_variable in $backend_variables; do
        if grep -q "^${possible_variable}[[:space:]]" <<< "$variables"; then
            variable="$possible_variable"
            break
        fi
    done
fi
if [ -z "$variable" ]; then
    die "Failed to find variable with terraform backend in GitLab CI/CD, please specify variable manually"
fi

if [ -z "$environment" ]; then
    if grep -q '[[:space:]]dev$' <<< "$variables"; then
        environment='dev'
    elif grep -q '[[:space:]]development$' <<< "$variables"; then
        environment='development'
    fi
fi

# false positive
# shellcheck disable=SC2016
timestamp "Getting backend config from GitLab variable '$variable' ${environment+environment '$environment'}"
backend_config="$(glab variable get "$variable" ${environment+-s "$environment"} )"

timestamp "Variable contents:"
echo >&2
echo "$backend_config" >&2
echo >&2
if ! grep -q backend <<< "$backend_config"; then
    die "ERROR: Backend not found in variable contents"
fi
read -r -p "Are you sure you want to overwrite '$backend_tf_file' with this content? (y/N) " answer
check_yes "$answer"
echo >&2
timestamp "Writing $backend_tf_file"
echo "$backend_config" > "$backend_tf_file"
