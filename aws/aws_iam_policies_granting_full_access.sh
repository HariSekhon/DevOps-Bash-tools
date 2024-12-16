#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-01-17 16:17:39 +0000 (Fri, 17 Jan 2020)
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
Finds policies granting full access in JSON format

Takes a while to run (eg. ~18 mins for ~700 policies)

If stderr is to terminal, prints progress counter in the form of num / total

Recommend to redirect stdout to a file ( > file.txt ) and just watch progress counter on stderr in terminal


$usage_aws_cli_jq_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

export AWS_DEFAULT_OUTPUT=json

echo "Getting policy list" >&2
policies="$(
    # get json to allow to filter later
    aws iam list-policies |
    jq -r '.Policies[] | [.Arn, .DefaultVersionId] | @tsv' # | head -n 10 || :
)"

num_policies="$(wc -l <<< "$policies")"
num_policies="${num_policies//[[:space:]]/}"

echo "Iterating over all $num_policies policies to find policies granting full access (this may take a while)" >&2
#{
#echo '['
#i=1
while read -r arn version; do
    echo "checking $arn version $version" >&2
    policy="$(aws iam get-policy-version --policy-arn "$arn" --version-id "$version")"
    if {
        # select any policies where Action is a string or an array containing * from granting all
        # XXX: if you want to find policies granting full access to a service like S3 just replace '*' with 's3:*'
        jq -r '.PolicyVersion | select(.Document.Statement[].Action == "*")' <<< "$policy" 2>/dev/null || :
        jq -r '.PolicyVersion | select(.Document.Statement[].Action.[] | index("*"))' <<< "$policy" 2>/dev/null || :
       } | grep -q .; then
        echo "WARNING: $arn GRANTS FULL ACCESS:"
        echo "$policy"
        echo
    fi
    # simple but we want progress numbers
    #echo -n '.' >&2
    # only print counter if stderr is to terminal
    #if [ -t 2 ]; then
    #    printf '\r%s/%s' "$i" "$num_policies" >&2
    #fi
    #if [ $i -lt "$num_policies" ]; then
    #    echo ','
    #fi
    #((i+=1))
done <<< "$policies"
#printf '\n' >&2
#echo ']'
#} # |
# doesn't give full document
#jq -r '.[].PolicyVersion.Document.Statement[] | select(.Action | index("*"))'
# gives full document, but not name and doesn't work when Action is string instead of array - doing test in loop now to output arn and handle both cases
#jq -r '.[].PolicyVersion | select(.Document.Statement[].Action | index("*"))'
