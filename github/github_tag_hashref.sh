#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-10-26 01:27:22 +0400 (Sat, 26 Oct 2024)
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
. "$srcdir/lib/github.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Returns the GitHub commit hashref for a given GitHub Actions owner/repo@tag or https://github.com/owner/repo@tag

Useful for pinning 3rd party GitHub Actionst to hashref instead of tag to follow GitHub Actions Best Practices:

    https://github.com/HariSekhon/Knowledge-Base/blob/main/github-actions.md#github-actions-best-practices
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<owner/action@v1.2,3>"

help_usage "$@"

num_args 1 "$@"

arg="$1"

arg="${arg## }"
arg="${arg%% }"

if ! [[ "$arg" =~ ^https://github.com/ ]]; then
    arg="${arg#https://github.com/}"
fi

if ! [[ "$arg" =~ @ ]]; then
    usage "no @<tag> found in arg: $arg"
fi

tag="${arg##*@}"
arg="${arg%%@*}"

if ! is_github_owner_repo "$arg"; then
    usage "arg does not match expected regex for GitHub owner/repo format: $arg"
fi

github_url="https://github.com/$arg"

git ls-remote --tags "$github_url" "$tag" |
grep -E "^[[:alnum:]]+[[:space:]]+refs/tags/$tag" |
awk '{print $1}'
