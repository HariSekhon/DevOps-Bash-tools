#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-01-17 16:17:39 +0000 (Fri, 17 Jan 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Dumps policies granting full access in JSON format
#
# Takes a while to run (eg. ~18 mins for ~700 policies)
#
# If stderr is to terminal, prints progress counter in the form of num / total
#
# Recommend to redirect stdout to a file ( > file.txt ) and just watch progress counter on stderr in terminal

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

echo "Getting policy list" >&2
policies="$(
    # get json to allow to filter later
    aws iam list-policies |
    jq -r '.Policies[] | [.Arn, .DefaultVersionId] | @tsv' # | head -n 10 || :
)"

num_policies="$(wc -l <<< "$policies")"
num_policies="${num_policies//[[:space:]]/}"

echo "Iterating over all $num_policies policies to find policies granting full access (this may take a while)" >&2
{
echo '['
i=1
while read -r arn version; do
    aws iam get-policy-version --policy-arn "$arn" --version-id "$version"
    # simple but we want progress numbers
    #echo -n '.' >&2
    # only print counter if stderr is to terminal
    if [ -t 2 ]; then
        printf '\r%s/%s' "$i" "$num_policies" >&2
    fi
    if [ $i -lt "$num_policies" ]; then
        echo ','
    fi
    ((i+=1))
done <<< "$policies"
printf '\n' >&2
echo ']'
} |
# doesn't give full document
#jq -r '.[].PolicyVersion.Document.Statement[] | select(.Action | index("*"))'
# gives full document, but not name and not doesn't work when Action is string instead of array
jq -r '.[].PolicyVersion | select(.Document.Statement[].Action | index("*"))'
