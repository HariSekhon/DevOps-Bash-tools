#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-11-24 12:40:18 +0000 (Wed, 24 Nov 2021)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Reads a value from the command line without echo'ing it on the screen and updates the given GCP Secret Manager secret

First argument is used as secret name - if not given prompts for it
Second argument is used as secret string value - if not given prompts for it with a non-echo'ing prompt (recommended)
Third or more args are passed to 'gcloud secrets'


GCloud SDK must be installed and configured
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<name> [<secret> <gcloud_options>]"

help_usage "$@"

min_args 1 "$@"

name="$1"
shift || :

if [ -z "$value" ]; then
    # doesn't echo, let's print a star per character instead as it's nicer feedback
    #read -s -p "Enter value: " value

    value=""
    prompt="Enter value: "
    while IFS= read -p "$prompt" -r -s -n 1 char; do
        if [[ "$char" == $'\0' ]]; then
            break
        fi
        prompt='*'
        value="${value}${char}"
    done
    echo
fi

gcloud secrets versions add "$name" --data-file - "$@" <<< "$value"
