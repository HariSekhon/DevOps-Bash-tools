#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-11 18:02:32 +0000 (Wed, 11 Mar 2020)
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

save_dir=".buildkite-pipelines"

# shellcheck disable=SC2034
usage_description="
Saves all BuildKite pipelines in your \$BUILDKITE_ORGANIZATION to local JSON files in \$PWD/$save_dir
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<curl_options>]"

help_usage "$@"

timestamp="$(date '+%F_%T' | sed 's/:/-/g')"

mkdir -pv "$save_dir"

"$srcdir/buildkite_pipelines.sh" "$@" |
while read -r pipeline; do
    json_file="$save_dir/$pipeline.json"
    echo "Saving pipeline '$pipeline' to '$json_file'"
    "$srcdir/buildkite_get_pipeline.sh" "$pipeline" "$@" > "$json_file"
    if jq -er '.message' < "$json_file" | grep -v '^null$' | grep '[A-Za-z]'; then
        exit 1
    fi
    # similar behaviour to bak function
    cp -av -- "$json_file" "$json_file.bak.$timestamp"
    echo
done
