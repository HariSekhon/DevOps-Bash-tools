#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-11-30 19:06:40 +0000 (Mon, 30 Nov 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://www.jetbrains.com/help/teamcity/rest-api-reference.html#VCS+Roots

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Lists TeamCity VCS roots - useful to find the IDs needed to download specific vcs roots using teamcity_vcs_roots_download.sh

Output Format:

<vcs_root_id>    <vcs_root_name>

Uses the adjacent teamcity_api.sh and jq (installed by 'make')

See teamcity_api.sh for required connection settings and authentication
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

#min_args 1 "$@"

# XXX: this key vcs-roots doesn't exist if there are none configured, eg. during teamcity.sh bootstrap, resulting in the old error
# jq: error (at <stdin>:0): Cannot iterate over null (null)
#
#output="$("$srcdir/teamcity_api.sh" /vcs-roots)"
#
#count="$(jq -r '.count' <<< "$output")"
#
#if [ "$count" -gt 0 ]; then
#    jq -r '.["vcs-root"][] | [.id, .name] | @tsv' <<< "$output"
#fi

# using special ? suffix operator now
"$srcdir/teamcity_api.sh" /vcs-roots |
jq -r '.["vcs-root"]? | .[]? | [.id, .name] | @tsv'
