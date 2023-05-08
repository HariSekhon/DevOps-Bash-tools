#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-08-01 14:51:44 +0100 (Mon, 01 Aug 2022)
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
Returns objects of a given type that have the given annotation set, optionally to a given value

Filtering by label is easy, but when you want to filter by annotation this is trickier

This script makes it easy to do in the current namespace

Output:

<namespace>    <name>    <annotation>=<value>


Kubectl needs to be installed in the \$PATH and configured with the right context
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<object_kind> <annotation> [<value> <kubectl_options>]"

help_usage "$@"

min_args 2 "$@"

kind="$1"
annotation="$2"
value="${3:-}"
shift || :
shift || :
shift || :

annotation_escaped="${annotation//./\\.}"
value_escaped="${value//\"/\\\"}"

# can't decompose this line across lines unfortunately for clarity, fails to parse
if [ -n "$value" ]; then
    kubectl get "$kind" "$@" -o jsonpath="{range .items[?(@.metadata.annotations.$annotation_escaped==\"$value_escaped\")]}{.metadata.namespace}{\"\\t\"}{.metadata.name}{\"\\t$annotation=\"}{.metadata.annotations.$annotation_escaped}{\"\\n\"}" | column -t
else
    kubectl get "$kind" "$@" -o jsonpath="{range .items[?(@.metadata.annotations.$annotation_escaped)]}{.metadata.namespace}{\"\\t\"}{.metadata.name}{\"\\t$annotation=\"}{.metadata.annotations.$annotation_escaped}{\"\\n\"}" | column -t
fi
