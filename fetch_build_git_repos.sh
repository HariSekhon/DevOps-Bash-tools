#!/bin/sh
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

set -eu
[ -n "${DEBUG:-}" ] && set -x
srcdir="`dirname $0`"

git_url="${GIT_URL:-https://github.com}"

make="${MAKE:-make}"
build="${BUILD:-}"

opts="${OPTS:-}"
if [ -z "${NO_TEST:-}" ]; then
    opts="$opts test"
fi
if [ -z "${NO_CLEAN:-}" ]; then
    opts="$opts clean"
fi

repolist="${@:-${REPOS:-}}"
if [ -n "$repolist" ]; then
    :
elif [ -f "$srcdir/repolist.txt" ]; then
    repolist="$(sed 's/#.*//' < "$srcdir/repolist.txt")"
else
    repolist="$(curl -sL https://raw.githubusercontent.com/HariSekhon/bash-tools/master/repolist.txt | sed 's/#.*//')"
fi

for repo in $repolist; do
    if ! echo "$repo" | grep -q "/"; then
        repo="harisekhon/$repo"
    fi
    repo_dir="${repo##*/}"
    [ -d "$repo_dir" ] || git clone "$git_url/$repo"
    pushd "$repo_dir"
    $make $build $opts
    popd
done
