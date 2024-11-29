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

For multiple source and destinations specify text files containing the paths, one line per path

For convenience:

- ignores hash # comment lines
- strips leading and trailing whitespaces
- validates each S3 URL's format
- validates the source and destination list lengths are the same
- validates each source and destination path suffix is the same
  - can disable this by 'export AWS_S3_SYNC_DIFFERENT_PATHS=true' before running this script if you really intend for
    the destination paths to be different to the source paths

These last two checks help prevent off-by-one human errors missing one path and spraying data to the wrong directories

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

log="aws_s3_sync-$(date '+%F_%H.%M.%S').log"

sources_file="$1"
destinations_file="$2"
shift || :
shift || :

sources=()
destinations=()

decomment(){
    sed '
        s/#.*$//;
        s/^[[:space:]]*//;
        s/[[:space:]]*$//;
        /^[[:space:]]*$/d
    ' "$1"
}

validate_s3_url(){
    local url="$1"
    if ! is_s3_url "$url"; then
        die "Invalid S3 URL given: $url"
    fi
}

# initially deduplicated this to a load_file() function but it turns out mapfile is only Bash 4+
# and Bash 3 has no native array passing, requiring array pass-by-name string and ugly evals
if ! [ -f "$sources_file" ]; then
    die "File not found: $sources_file"
fi

timestamp "Capturing log to: $log"
{

timestamp "Loading sources from file '$sources_file'"
while IFS= read -r line; do
    validate_s3_url "$line"
    sources+=("$line")
done < <(decomment "$sources_file")
sources_len="${#sources[@]}"
timestamp "$sources_len sources loaded"
echo

if ! [ -f "$destinations_file" ]; then
    die "File not found: $destinations_file"
fi
timestamp "Loading destinations from file '$destinations_file'"
while IFS= read -r line; do
    validate_s3_url "$line"
    destinations+=("$line")
done < <(decomment "$destinations_file")
destinations_len="${#destinations[@]}"
timestamp "$destinations_len destinations loaded"
echo

timestamp "Sanity check: Verifying source and destination list lengths are the same"
if [ "$sources_len" != "$destinations_len" ]; then
    die "ERROR: length of sources and destinations arrays of paths are not equal in length: sources ($sources_len) vs destinations ($destinations_len)"
fi

if [ "${AWS_S3_SYNC_DIFFERENT_PATHS:-}" != true ]; then
    timestamp "Sanity check: Verifying source and destination suffix paths are the same"
    for ((i=0; i < sources_len; i++)); do
        src="${sources[i]}"
        dest="${destinations[i]}"
        src_path="${src#s3://}"
        src_path="${src_path#*/}"
        dest_path="${dest#s3://}"
        dest_path="${dest_path#*/}"
        if [ "$src_path" != "$dest_path" ]; then
            echo
            error "Source path suffix '$src' does not match destination path suffix '$dest'"
            echo
            die "If this is really intentional, 'export AWS_S3_SYNC_DIFFERENT_PATHS=true' before running this script"
        fi
    done
    echo
fi

for ((i=0; i < sources_len; i++)); do
    src="${sources[i]}"
    dest="${destinations[i]}"

    timestamp "Syncing AWS S3 '$src' to '$dest'"
    aws s3 sync "$src" "$dest" "$@"
done
echo
# we've already verified above that $sources_len and $destination_len are the same
timestamp "AWS S3 Sync completed for $sources_len S3 URL paths"

} 2>&1 |
# aws s3 sync seems to output \r messing up the log lines
tr '\r' '\n' |
tee -a "$log"
