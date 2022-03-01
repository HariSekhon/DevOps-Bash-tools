#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-02-28 19:18:26 +0000 (Mon, 28 Feb 2022)
#
#  https://github.com/HariSekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

# sourcing lib.sh results in Terraform errors 'is_verbose: command not found'

usage="
Terraform external program that returns a list of top-level resource names for a given type

Workaround for Terraform Splat expressions not supporting top level resource names

    https://github.com/hashicorp/terraform/issues/19931

Returns a JSON output in format 'map[string]=string' where both the key and value are the name of the resource

Example:

    ${0##*/} github_repository

Terraform:

    data \"external\" \"github_repos\" {
        program = [\"/path/to/${0##*/}\", \"github_repository\"]
    }

    resource \"github_team_repository\" \"devops\" {
      permission = \"admin\"
      for_each   = data.external.github_repos.result
      repository = each.key
      team_id    = github_team.devops.id
    }


Requires Terraform and jq to be installed and configured


usage: ${0##*/} <resource_type>
"

if [ $# != 1 ] || [[ "$1" =~ ^- ]]; then
    echo "$usage"
    exit 3
fi

resource_type="$1"

terraform state list  |
grep "^$resource_type\\." |
awk -F. '{print $2}' |
jq -MR -s -c 'split("\n")[] |
              select(. != "") |
              { (.) : . }' |
jq -n 'reduce inputs as $in (null; . + $in)'
