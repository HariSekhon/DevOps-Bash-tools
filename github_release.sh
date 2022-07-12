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

# shellcheck disable=SC1090
. "$srcdir/lib/github.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Creates a GitHub Release and Git Tag, auto-incrementing the default vYYYY.NN release if one isn't given

The first argument is the version, which is recommended to set to vN.N.N eg. v1.0.0 as per semantic versioning standards

If the first argument is 'date', will determine the next available release in the format vYYYY-MM-DD.NN where NN is incremented from 1
If the first argument is 'month', will determine the next available release in the format vYYYY-MM.NN
If the first argument is 'year', will determine the next available release in the format vYYYY.NN (the default if no version is specified)

$usage_github_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<version> <title> <description>]"

help_usage "$@"

#min_args 1 "$@"

version="${1:-year}"
title="${2:-}"
description="${3:-}"

generate_version=0
prefix='v'
if [ -n "${NO_GITHUB_RELEASE_PREFIX:-}" ]; then
    prefix=''
fi

if [ "$version" = year ]; then
    version="${prefix}$(date '+%Y')"
    generate_version=1
elif [ "$version" = month ]; then
    version="${prefix}$(date '+%Y-%m')"
    generate_version=1
elif [ "$version" = day ]; then
    version="${prefix}$(date '+%F')"
    generate_version=1
fi

if [ "$generate_version" = 1 ]; then
    latest_releases="$(gh release list --exclude-drafts | awk '{print $1}')"

    number="$(grep -Eo "^$version"'\.\d+' <<< "$latest_releases" | head -n 1 | sed "s/^$version\\.//" || echo 1)"

    # increment the number
    while grep -Fxq "$version.$number" <<< "$latest_releases"; do
        ((number+=1))
        if [ $number -gt 9999 ]; then
            die "FAILED to find unused release in format '$version.NN'"
        fi
    done

    version+=".$number"
fi

if is_blank "$title"; then
    title="$version"
fi

gh release create "$version" --title "$version" --notes "$description"
