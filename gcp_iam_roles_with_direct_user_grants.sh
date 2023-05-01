#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-02-19 11:59:27 +0000 (Fri, 19 Feb 2021)
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
Find GCP roles that have been granted directly to a user in the current / given GCP project

Useful to find IAM permissions in violation of best practice group-oriented management

If you set the environment variable \$DUMP_ROLES to any value, will output a JSON output for each role so you can see the offending user members


Requires GCloud SDK to be installed and configured
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<project_id>]"

help_usage "$@"

project="${1:-}"

if is_blank "$project"; then
    project="$(gcloud config list --format='get(core.project)')"
fi

not_blank "$project" || die "ERROR: no project specified and GCloud SDK core.project property not set in config"

gcloud projects get-iam-policy "$project" --format=json |
jq -r ".bindings[] | select(.members[] | test(\"^user:\")) | .role" |
sort -u |
if [ -n "${DUMP_ROLES:-}" ]; then
    while read -r role; do
        gcloud projects get-iam-policy "$project" --format=json |
        jq -r ".bindings[] | select(.role == \"$role\")"
    done
else
    cat
fi
