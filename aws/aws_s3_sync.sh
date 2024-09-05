#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-09-05 12:18:36 +0200 (Thu, 05 Sep 2024)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
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
. "$srcdir/lib/aws.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Syncs multiple AWS S3 URLs from file lists

Needed because clients often request copies of data ranges of multiple directories between environment buckets for test data

For multiple source and destinations specify text files containing the paths, one line per path, with # comment lines ignored for convenience

If the arguments given are not files, assumes them to be single literal S3 paths

You can populate the source and destination path files using native Bash like this:

    echo s3://prod-landing-bucket/transactions/2023-06-{20..30} | tr ' ' '\n' > sources.txt

    echo s3://uat-landing-bucket/transactions/2023-06-{20..30} | tr ' ' '\n' > destinations.txt


Consider adding the --dryrun option to the end of the script args when running it the first time


$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<sources.txt> <destinations.txt> [<aws_cli_options>]"

help_usage "$@"

min_args 2 "$@"

source="$1"
destination="$2"
shift || :
shift || :

sources=()
destinations=()

decomment(){
    sed 's/#.*$//; /^[[:space:]]*$/d' "$1"
}

validate_s3_url(){
    if ! is_s3_url "$1"; then
        die "Invalid S3 URL given: $1"
    fi
}

# initially deduplicated this to a load_file() function but it turns out mapfile is only Bash 4+
# and Bash 3 has no native array passing, requiring array pass-by-name string and ugly evals
if [ -f "$source" ]; then
    timestamp "Loading sources from file '$source'"
    while IFS= read -r line; do
        validate_s3_url "$line"
        sources+=("$line")
    done < <(decomment "$source")
else
    sources=("$source")
fi
sources_len="${#sources[@]}"
timestamp "$sources_len sources loaded"
echo

if [ -f "$destination" ]; then
    timestamp "Loading destinations from file '$destination'"
    while IFS= read -r line; do
        validate_s3_url "$line"
        destinations+=("$line")
    done < <(decomment "$destination")
else
    destinations=("$destination")
fi
destinations_len="${#destinations[@]}"
timestamp "$destinations_len destinations loaded"
echo

if [ "$sources_len" != "$destinations_len" ]; then
    die "ERROR: length of sources and destinations arrays of paths are not equal in length: sources ($sources_len) vs destinations ($destinations_len)"
fi

for ((i=0; i < sources_len; i++)); do
    src="${sources[i]}"
    dest="${destinations[i]}"

    timestamp "Syncing AWS S3 '$src' to '$dest'"
    aws s3 sync "$src" "$dest" "$@"
done

echo
timestamp "AWS S3 Sync completed"
