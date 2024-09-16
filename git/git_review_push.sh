#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-08-05 15:49:27 +0100
#  (migrated out of .bash.d/git.sh and gitconfig for use in IntelliJ)
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
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Shows a git diff of what would be pushed and if you hit enter then pushes to origin remote

See also git_remotes_set_multi_origin.sh if you want to be able to push to multiple origin remotes for resilience
by using different platforms eg. GitHub, GitLab, Azure DevOps and Bitbucket

Lazy but awesome for lots of daily quick intermediate diff-review-pushes workflow

Migrated from .gitconfig alias and vimrc hotkey

Ported to external script be callable from IntelliJ as an External Tool because it's less keystrokes
and no mouse movement compared to IntelliJ's own hot key git commit tooling
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

num_args 0 "$@"

timestamp "Pulling to ensure we have the latest remote contents"
echo >&2
git pull
echo >&2

timestamp "Comparing HEAD vs FETCH_HEAD"
echo >&2
timestamp "Checking git log"
commits="$(git log FETCH_HEAD..HEAD)"
echo >&2

if is_blank "$commits"; then
    timestamp "No changes to push"
    exit 0
fi

timestamp "Getting diff"
diff="$(git diff --color=always FETCH_HEAD..HEAD | tee /dev/stderr)"

if is_blank "$diff"; then
    timestamp "No changes to push, but commit difference (empty commits?)"
    echo >&2
fi

read -r -p "Push to origin remote? (Y/n) " answer
echo >&2

check_yes "${answer:-Y}"

git push

echo >&2
timestamp "Git Diff Review Push completed"
