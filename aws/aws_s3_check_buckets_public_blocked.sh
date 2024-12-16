#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-05-31 10:25:27 +0100 (Tue, 31 May 2022)
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
. "$srcdir/lib/aws.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Iterates all buckets in the current AWS account and checks their Block Public Access settings

Exits with error code 2 if buckets are found which do not have this protection fully set,
and exits with error code 1 if no buckets found

Set the environment variable QUIET to any value to omit the header and summary warning lines

Parallelized to get through bucket list more quickly, set NOPARALLEL env var to any value to serialize for debugging
For 64 buckets parallelization took the runtime from 166-168 seconds down to 21-40 seconds


$usage_aws_cli_jq_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

max_args 1

region="${1:-}"
shift || :

if [ -n "$region" ]; then
    export AWS_DEFAULT_REGION="$region"
fi

export AWS_DEFAULT_OUTPUT=json

num_buckets=0
num_non_compliant_buckets=0

parallelism="$(cpu_count)"
if [ "$parallelism" -gt 20 ]; then
    # cap the parallelism to not spam AWS API and risk getting blocked
    parallelism=10
fi

if [ -n "${NOPARALLEL:-}" ]; then
    parallelism=1
fi

shopt -s nocasematch

start_time="$(date '+%s')"

max_bucket_name_len="$(aws s3api list-buckets | jq -rM '.Buckets[].Name | length' | jq -srM 'max')"
# XXX: has to be exported for subshell parallel function below to access it
export format_string='%-25s\t%-15s\t'"%-${max_bucket_name_len}s"'\t%-16s\t%-17s\t%-18s\t%s\n'

if [ -z "${QUIET:-}" ] || is_piped; then
    # false positive, the format string is carefully constructed
    # shellcheck disable=SC2059
    printf "$format_string" 'Creation Timestamp' Region Bucket BlockPublicAcls IgnorePublicAcls BlockPublicPolicy RestrictPublicBuckets >&2
fi

commands=""

while read -r creation_timestamp bucket; do
    commands+="
    bucket_info '$bucket' '$creation_timestamp'"
done < <(
    aws s3api list-buckets |
    jq -r '.Buckets[] | [.CreationDate, .Name] | @tsv'
)

bucket_info(){
    [ -n "${DEBUG:-}" ] && set -x
    local bucket="$1"
    local creation_timestamp="$2"
    local region
    local policy
    region="$(aws s3api get-bucket-location --bucket "$bucket" || :)"
    if [ -n "$region" ]; then
        region="$(jq -r '.LocationConstraint' <<< "$region")"
    else
        region="unknown"
        echo "FAILED to get region for bucket '$bucket', skipping..." >&2
    fi
    policy="$(aws s3api get-public-access-block --bucket "$bucket" 2>/dev/null || :)"
    if [ -n "$policy" ]; then
        # XXX: must align with read command a few lines down
        policy="$(jq -r '.PublicAccessBlockConfiguration | [ .BlockPublicAcls, .IgnorePublicAcls, .BlockPublicPolicy, .RestrictPublicBuckets ] | @tsv' <<< "$policy")"
    else
        # Block Access Policy not set
        policy="unset unset unset unset"
    fi
    # XXX: must align with jq command a few lines up
    read -r BlockPublicAcls IgnorePublicAcls BlockPublicPolicy RestrictPublicBuckets <<< "$policy"
    # false positive, the format string is carefully constructed
    # shellcheck disable=SC2059
    # XXX: must align with read command in loop further down, and header line above
    printf "$format_string" "$creation_timestamp" "$region" "$bucket" "$BlockPublicAcls" "$IgnorePublicAcls" "$BlockPublicPolicy" "$RestrictPublicBuckets"
}
export -f bucket_info

# XXX: must align with bucket_info() output
while read -r creation_timestamp region bucket BlockPublicAcls IgnorePublicAcls BlockPublicPolicy RestrictPublicBuckets; do
    # false positive, the format string is carefully constructed
    # shellcheck disable=SC2059
    printf "$format_string" "$creation_timestamp" "$region" "$bucket" "$BlockPublicAcls" "$IgnorePublicAcls" "$BlockPublicPolicy" "$RestrictPublicBuckets"
    if [[ "$BlockPublicAcls" =~ false|unset ]] ||
       [[ "$IgnorePublicAcls" =~ false|unset ]] ||
       [[ "$BlockPublicPolicy" =~ false|unset ]] ||
       [[ "$RestrictPublicBuckets" =~ false|unset ]]; then
        ((num_non_compliant_buckets+=1))
    fi
    ((num_buckets+=1))
done < <(parallel -j "$parallelism" <<< "$commands")

if [ -z "${QUIET:-}" ]; then
    end_time="$(date +%s)"
    time_taken="$((end_time - start_time))"
    echo >&2
    echo "Time taken: $time_taken secs" >&2
    echo >&2
fi
if [ $num_buckets -eq 0 ]; then
    echo "WARNING: no buckets found" >&2
    exit 1
elif [ $num_non_compliant_buckets -eq 0 ]; then
    if [ -z "${QUIET:-}" ]; then
        echo "OK: All $num_buckets buckets found to be compliant blocking public access" >&2
    fi
else
    echo "WARNING: $num_non_compliant_buckets/$num_buckets buckets found without public access blocked!" >&2
    exit 2
fi
