#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-07-12 14:18:52 +0100 (Tue, 12 Jul 2022)
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
. "$srcdir/lib/github.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Creates a Git Tag for the current repo checkout, auto-incrementing the default vYYYY.NN release if one isn't given

The first argument is an optional version, which is recommended to set to vN.N.N eg. v1.0.0 as per semantic versioning standards

If the first argument is 'day' or 'date', will determine the next available release in the format vYYYYMMDD.NN where NN is incremented from 1
If the first argument is 'month', will determine the next available release in the format vYYYYMM.NN
If the first argument is 'year', will determine the next available release in the format vYYYY.NN

If no argument is given, defaults to generating a 'year' version in the format vYYYY.NN

These formats don't have dashes in them like ISO dates so that if you move from YYYY to YYYYMM format or YYYYMMDD format, software will recognize the newer format as the highest version number ie. the latest version


Requires the Git command to be installed

Don't forget to 'git push --tags' to send the tag upstream
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<version> <commit>]"

help_usage "$@"

#min_args 1 "$@"

version="${1:-year}"
commit="${2:-HEAD}"
shift || :
shift || :

generate_version=0
prefix='v'
if [ -n "${NO_GIT_RELEASE_PREFIX:-}" ]; then
    prefix=''
fi

if [ "$version" = year ]; then
    version="${prefix}$(date '+%Y')"
    generate_version=1
elif [ "$version" = month ]; then
    version="${prefix}$(date '+%Y%m')"
    generate_version=1
elif [ "$version" = day ] || [ "$version" = date ]; then
    version="${prefix}$(date '+%Y%m%d')"
    generate_version=1
fi

if [ "$generate_version" = 1 ]; then
    existing_tags="$(git tags)"

    number="$(grep -Eo "^$version"'\.\d+' <<< "$existing_tags" | head -n 1 | sed "s/^$version\\.//" || echo 1)"

    # increment the number
    while grep -Fxq "$version.$number" <<< "$existing_tags"; do
        ((number+=1))
        if [ $number -gt 9999 ]; then
            die "FAILED to find unused tag version in format '$version.NN'"
        fi
    done

    version+=".$number"
fi

timestamp "Generating tag '$version' on commit '$commit'"
git tag "$version" "$commit"
timestamp "Generated release tag '$version'"
