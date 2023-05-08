#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-03-30 11:13:53 +0100 (Wed, 30 Mar 2022)
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
Prints AWS CodeCommit Git credentials from a standard AWS HTTPS Git credentials CSV export file as shell export statements

    export GIT_USER=...
    export GIT_PASSWORD=...

Useful to quickly switch your shell to some exported credentials from a service account for testing permissions
or pipe to upload to a CI/CD system via an API, eg. the adjacent scripts:

    github_actions_repo*_set_secret.sh
    gitlab_*_set_env_vars.sh
    circleci_*_set_env_vars.sh
    bitbucket_*_set_env_vars.sh
    terraform_cloud_*_set_vars.sh
    kubectl_kv_to_secret.sh

Examples:

    # format downloaded from the user's IAM -> Security Credentials -> section HTTPS Git credentials for AWS CodeCommit

    eval \$(${0##*/} hari_codecommit_credentials.csv)


You can then use these credentials in commands, but note that if the \$GIT_PASSWORD contains slashes you will need to urlencode it:

    GIT_PASSWORD_URLENCODED=\"\$(urlencode.sh <<< \"\$GIT_PASSWORD\")\"

    git clone \"https://\$GIT_USER:\$GIT_PASSWORD_URLENCODED@git-codecommit.eu-west-2.amazonaws.com/v1/repos/myrepo\"
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<username>_codecommit_credentials.csv"

help_usage "$@"

min_args 1 "$@"

csv="$1"

if ! [ -f "$csv" ]; then
    die "ERROR: File not found: $csv"
fi

# people may rename their credentials file
#if ! [[ "$csv" =~ ^.+_codecommit_credentials.csv ]]; then
#    die "ERROR: Wrong filename, should be in format *_codecommit_credentials.csv"
#fi

# XXX: this CSV credentials files come in DOS format unlike other CSV credential downloads for AWS CLI etc.
if ! tr -d '\r' < "$csv" | grep -Fxq 'User Name,Password'; then
    die "ERROR: Expected 'User Name,Password' header not found in file '$csv'"
fi

lines="$(wc -l "$csv" | awk ' {print $1}')"

if ! [ "$lines" -eq 2 ]; then
    die "ERROR: wrong number of lines found in CSV credentials file, expected 2, got $lines"
fi

tr -d '\r' < "$csv" |
tail -n 1 |
awk -F, '{
    print "export GIT_USER="$1
    print "export GIT_PASSWORD="$2
}'
