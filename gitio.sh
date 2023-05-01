#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-13 16:05:56 +0100 (Thu, 13 Aug 2020)
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
Creates a git.io shortcut URL for your GitHub project

Beware that the first shortname for a URL will stick, ignoring subsequent requests

See here for more details:

https://github.blog/2011-11-10-git-io-github-url-shortener/

https://aletheia.icu/~badt/git-io/

https://gist.github.com/dikiaap/01f5e2ba3c738012aef0a8f524a6e207
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<github_user>/<github_repo> <shortname>"

help_usage "$@"

min_args 2 "$@"

github_repo="$1"

shortname="$2"

if ! [[ "$github_repo" =~  / ]]; then
    usage
fi

if ! [[ "$github_repo" =~ https?:// ]]; then
    github_repo="https://github.com/$github_repo"
fi

curl https://git.io/ -i -F "url=$github_repo" -F "code=$shortname"
