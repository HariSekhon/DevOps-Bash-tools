#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2016-01-17 12:14:06 +0000 (Sun, 17 Jan 2016)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/git.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Updates all Git submodules in the current Git repo to the latest default branch commit and commits them
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

num_args 0 "$@"

if ! is_git_repo .; then
	die 'ERROR: Not in a Git repository!'
fi

git pull --no-edit

for submodule in $(git submodule | awk '{print $2}'); do
	[ -d "$submodule" ] || continue
	[ -L "$submodule" ] && continue
	pushd "$submodule" ||
	die "ERROR: Failed to pushd to submodule directory: $submodule"
	git stash
	git checkout "$(default_branch)"
	git pull --no-edit
	git submodule update --init --remote
	popd
done

echo

for submodule in $(git submodule | awk '{print $2}'); do
	[ -d "$submodule" ] || continue
	[ -L "$submodule" ] && continue
	if ! git status "$submodule" |
		 grep -q nothing; then
		git commit -m "updated $submodule" "$submodule" ||
		die "ERROR: Failed to commit submodule update"
	fi
done

echo

for submodule in $(git submodule | awk '{print $2}'); do
	[ -d "$submodule" ] || continue
	[ -L "$submodule" ] && continue
	pushd "$submodule" || continue
	git stash pop
	popd
done
