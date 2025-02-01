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

This is also useful for simpler use cases:

    git submodule foreach --recursive 'git checkout master && git pull'

But this script will figure out a mix or repos on master vs main vs develop branches as trunk
and has better output and error handling
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

num_args 0 "$@"

if ! is_git_repo .; then
	die 'ERROR: Not in a Git repository!'
fi

git_root="$(git_root)"

cd "$git_root"

git pull --no-edit

submodules="$(
    git submodule |
    awk '{print $2}'
)"

if is_blank "$submodules"; then
    echo "No Git Submodules detected"
    exit 0
fi

timestamp "Git submodules detected:"
echo >&2
echo "$submodules" >&2
echo >&2

for submodule in $(git submodule | awk '{print $2}'); do
	[ -d "$submodule" ] || continue
	[ -L "$submodule" ] && continue
    timestamp "Updating submodule: $submodule"
    echo >&2
	pushd "$submodule" ||
        die "ERROR: Failed to pushd to submodule directory: $submodule"
	git stash
	git checkout "$(default_branch)"
	git pull --no-edit
	git submodule update --init --remote
	git submodule update --recursive
	popd
    echo >&2
done

for submodule in $(git submodule | awk '{print $2}'); do
	[ -d "$submodule" ] || continue
	[ -L "$submodule" ] && continue
    timestamp "Committing submodule: $submodule"
    echo >&2
	if ! git status "$submodule" |
		 grep -q nothing; then
		git commit -m "updated $submodule" "$submodule" ||
		die "ERROR: Failed to commit submodule update"
	fi
    echo >&2
done

echo

for submodule in $(git submodule | awk '{print $2}'); do
	[ -d "$submodule" ] || continue
	[ -L "$submodule" ] && continue
    timestamp "Committing submodule: $submodule"
    echo >&2
	pushd "$submodule" ||
        die "ERROR: Failed to pushd to submodule directory: $submodule"
	git stash pop
	popd
    echo >&2
done
