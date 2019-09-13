#!/usr/bin/env bash
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
srcdir="$(dirname "$0")"

git_url="${GIT_URL:-https://github.com}"

make="${MAKE:-make}"
build="${BUILD:-build}"

opts="${OPTS:-}"
if [ -z "${NO_TEST:-}" ]; then
    opts="$opts test"
fi

if [ $# -gt 0 ]; then
    repolist="$*"
else
    repolist="${*:-${REPOS:-}}"
    if [ -n "$repolist" ]; then
        :
    elif [ -f "$srcdir/setup/repolist.txt" ]; then
        repolist="$(sed 's/#.*//; /^[[:space:]]*$/d' < "$srcdir/setup/repolist.txt")"
    else
        repolist="$(curl -sL https://raw.githubusercontent.com/HariSekhon/bash-tools/master/setup/repolist.txt | sed 's/#.*//')"
    fi
fi

if [ -z "${JAVA_HOME:-}" ]; then
    set +e
    JAVA_HOME="$(command -v java 2>/dev/null)/.."
    if [ -z "${JAVA_HOME:-}" ]; then
        JAVA_HOME="$(type java 2>/dev/null | sed 's/java is //; s/hashed //; s/[()]//g')"
    fi
    set -e
    if [ -z "${JAVA_HOME:-}" ]; then
        JAVA_HOME="/usr"
    fi
fi

if type yum &>/dev/null; then
    yum install -y git make
elif type apt-get &>/dev/null; then
    apt-get update
    apt-get install -y --no-install-recommends git make
elif type apk &>/dev/null; then
    apk update
    apk add git make
fi

for repo in $repolist; do
    if ! echo "$repo" | grep -q "/"; then
        repo="HariSekhon/$repo"
    fi
    repo_dir="${repo##*/}"
    if ! [ -d "$repo_dir" ]; then
        git clone "$git_url/$repo"
    fi
    pushd "$repo_dir"
    git pull
    git submodule update --init
    #  shellcheck disable=SC2086
    if [ -z "${NOBUILD:-}" ] &&
       [ -z "${NO_BUILD:-}" ]; then
        "$make" "$build" $opts
    fi
    if [ -f /.dockerenv ]; then
        for x in system-packages-remove clean deep-clean; do
            if grep -q "^$x:" Makefile bash-tools/Makefile.in 2>/dev/null; then
                $make "$x"
            fi
        done
    fi
    popd
done
