#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-08-02 12:35:16 +0100 (Tue, 02 Aug 2022)
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
Finds all kustomization.yml/yaml files under the current or given path and runs datree kustomize test for each one

Retains the highest number exit code to ensure no earlier errors are lost

To pass arguments to Kustomize instead of Datree, you must use --

Example:

    ${0##*/} . -- --enable-helm

"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<path> <datree_options>]"

check_env_defined "DATREE_TOKEN"

help_usage "$@"

#min_args 1 "$@"

# XXX: this code has now been added to the official Datree docs:
#
#   https://hub.datree.io/integrations/kustomize-support#testing-multiple-kustomizations

path="${1:-.}"
shift || :

final_exit_code=0

while read -r kustomization; do
    dir="$(dirname "$kustomization")"
    echo "Datree Kustomization Test: $kustomization"
    set +e
    datree kustomize test "$dir" "$@"
    exitcode=$?
    set -e
    if [ "$exitcode" -gt "$final_exit_code" ]; then
        final_exit_code="$exitcode"
    fi
    # Datree outputs enough space at the end of each run already
    #echo
done < <(find "$path" -type f -name 'kustomization.y*ml')

if [ "$final_exit_code" = 0 ]; then
    echo "Success"
else
    echo "Violations found, returning exit code $final_exit_code"
fi
exit "$final_exit_code"
