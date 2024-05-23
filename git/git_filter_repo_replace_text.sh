#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-01-30 19:05:59 +0000 (Tue, 30 Jan 2024)
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
Rewrites the Git history using git filter-repo to replace a given token with another to scrub history

<git_options> - passed literally to 'git filter-repo', can use this to only rewrite a revision range, eg. <starting_hashref>..<ending_hashref>


DANGER: this rewrites Git history.
        Do not use this carelessly as it rewrites Git history.
        Always have a backup.
        Do not do this on pushed branches unless you are an Expert and intend to
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<old_token> [<new_token>] [<git_options>]"

help_usage "$@"

min_args 2 "$@"

old_token="$1"
new_token="$2"
shift || :
shift || :

opts=()
if [ -n "${FORCE_GIT_REWRITE:-}" ]; then
    opts+=(-f)
fi

if [ "${#old_token}" -lt 8 ]; then
    echo "
DANGER: refusing to replace a token less than 8 characters because this is likely to match other tokens and cause serious unintended consequences which could destroy your code base

If you really intend to do this and known what you're doing, edit this code to bypass
" >&2
    exit 1
fi

echo
echo "DANGER!!!"
echo
echo -n "You are about to replace all substrings of '$old_token' to '$new_token' - this could seriously damage you code base if you careless use a token that matches elsewhere"
echo
echo "Have you taken a backup?"
echo
read -r -p "DANGER: are you absolutely sure? (y/N)  " answer
echo

is_yes "$answer" || die "Aborting"

timestamp "Starting git filter-repo replacement"
echo

git filter-repo "${opts[@]}" --replace-text <(echo "$old_token==>$new_token") "$@"
