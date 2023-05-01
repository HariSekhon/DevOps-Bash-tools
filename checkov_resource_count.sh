#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-02-22 15:20:27 +0000 (Tue, 22 Feb 2022)
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
Counts the number of resources Checkov is scanning in the current or given directory

Useful to estimate Bridgecrew Cloud costs which are charged per resource

This can take a while to run on large directories with lots of resources

The first argument should be a directory (defaults to '.' for \$PWD)
The second argument onwards are passed as-is directly to the 'checkov' command

Alternatively, use a local .checkov.yaml config file to configure checkov settings,
such as multiple directories or skip directories, eg:

    https://github.com/HariSekhon/Templates/blob/master/.checkov.yaml


Requires Checkov, awk and jq to be installed
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<directory> <checkov_args>]"

help_usage "$@"

check_bin awk
check_bin jq

#min_args 1 "$@"

dir="${1:-.}"
shift || :

# user should supply args or local .checkov.yaml if they want additional checkov settings
#
# gets lots of errors without --download-external-modules=true, eg:
# 2022-02-22 15:27:26,308 [MainThread  ] [WARNI]  Failed to download module x/y/z:n.n.n
#
json_data="$(checkov -d "$dir" --download-external-modules true -o json "$@")"

jq_count="$(
    jq '
        if
            type=="array" then .
        else
            [.]
        end |
        [ .[].summary.resource_count ] |
        add
        ' <<< "$json_data"
)"

# opening brace must be on same line as the /regex_filter/, otherwise will apply to all lines
# substr to strip the trailing json comma from 'resource_count: <number>,'
awk_count="$(
    awk '/resource_count/ {
            resource_count = substr($2, 0, length($2) - 1)
            total_resource_count += resource_count
         }
        END {
            print total_resource_count
        }' <<< "$json_data"
)"

if [ "$jq_count" != "$awk_count" ]; then
    die 'Parsing inconsistency detected between jq and awk on the checkov json data. Checkov output format may have changed'
fi

echo "$jq_count"
