#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2016-01-17 12:14:06 +0000 (Sun, 17 Jan 2016)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "$0")" && pwd)"

# access to useful functions and aliases
# shellcheck disable=SC1090
#. "$srcdir/.bash.d/aliases.sh"
#. "$srcdir/.bash.d/functions.sh"
. "$srcdir/.bash.d/git.sh"

#git_url="${GIT_URL:-https://github.com}"

#git_base_dir=~/github

#mkdir -pv "$git_base_dir"

#cd "$git_base_dir"

opts="${OPTS:-}"
if [ -z "${NO_TEST:-}" ]; then
    opts="$opts test"
fi

repofile="$srcdir/setup/repolist.txt"

repolist="${REPOS:-}"
if [ -n "$repolist" ]; then
    :
elif [ -f "$repofile" ]; then
    echo "processing repos from file: $repofile"
    repolist="$(sed 's/#.*//; /^[[:space:]]*$/d' < "$repofile")"
else
    echo "fetching repos from GitHub repo list"
    repolist="$(curl -sSL https://raw.githubusercontent.com/HariSekhon/bash-tools/master/setup/repolist.txt | sed 's/#.*//')"
fi

for repo in $repolist; do
    if ! echo "$repo" | grep -q "/"; then
        repo="HariSekhon/$repo"
    fi
    repo_dir="${repo##*/}"
    repo_dir="${repo_dir##*:}"
    repo_dir="$srcdir/../$repo_dir"
    repo="${repo%%:*}"
    if ! [ -d "$repo_dir" ]; then
        #git clone "$git_url/$repo" "$repo_dir"
        continue
    fi
    pushd "$repo_dir" >/dev/null
    echo "========================================"
    echo "$repo - $PWD"
    echo "========================================"
    eval "$@"
    popd >/dev/null
    echo
done
