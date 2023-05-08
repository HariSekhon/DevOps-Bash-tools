#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-12-03 16:59:48 +0000 (Fri, 03 Dec 2021)
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
Prints AWS credentials from a standard AWS CSV export file or access key export CSV as shell export statements

    export AWS_ACCESS_KEY_ID=AKIA...
    export AWS_SECRET_ACCESS_KEY=...

Supports new user and new access key csv file formats eg. 'Download .csv file' when you create an AWS access key in the console

Useful to quickly switch your shell to some exported credentials from a service account for testing permissions
or pipe to upload to a CI/CD system via an API, eg. the adjacent scripts:

    jenkins_cred_add*.sh
    github_actions_repo*_set_secret.sh
    gitlab_*_set_env_vars.sh
    circleci_*_set_env_vars.sh
    bitbucket_*_set_env_vars.sh
    terraform_cloud_*_set_vars.sh
    kubectl_kv_to_secret.sh

Examples:

    eval \$(${0##*/} new_user_credentials.csv)  # format downloaded when creating a user

    eval \$(${0##*/} hari_accessKeys.csv)       # format downloaded when creating an access key
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="credential.csv"

help_usage "$@"

min_args 1 "$@"

csv="$1"

if ! [ -f "$csv" ]; then
    die "ERROR: File not found: $csv"
fi

if ! grep -Fq 'AKIA' "$csv"; then
    die "ERROR: Access Key not found in file '$csv'"
fi

# for CSV created at access key creation time
if tr -d '\r' < "$csv" | grep -Fq 'Access key ID,Secret access key'; then
    # access keys are prefixed with AKIA, skips header row by selecting the row with the AKIA key
    awk -F, '/AKIA/{
        print "export AWS_ACCESS_KEY_ID="$1
        print "export AWS_SECRET_ACCESS_KEY="$2
    }' "$csv" | tr -d '\r'
# for CSV created at user creation time
elif tr -d '\r' < "$csv" | grep -Fq 'User name,Password,Access key ID,Secret access key,Console login link'; then
    awk -F, '/AKIA/{
        print "export AWS_ACCESS_KEY_ID="$3
        print "export AWS_SECRET_ACCESS_KEY="$4
    }' "$csv" | tr -d '\r'
else
    die "ERROR: unrecognized CSV header line, may have changed so code may need an update"
fi
