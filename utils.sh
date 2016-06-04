#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2015-05-25 01:38:24 +0100 (Mon, 25 May 2015)
#
#  https://github.com/harisekhon/pytools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -eu
[ -n "${DEBUG:-}" ] && set -x
srcdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

hr(){
    echo "================================================================================"
}

section(){
    hr
    "$srcdir/center80.sh" "$@"
    hr
}

# TODO:
#export SPARK_HOME="$(ls -d tests/spark-*-bin-hadoop* | head -n 1)"

type isExcluded &>/dev/null || . "$srcdir/excluded.sh"

is_linux(){
    if [ "$(uname -s)" = "Linux" ]; then
        return 0
    else
        return 1
    fi
}

is_mac(){
    if [ "$(uname -s)" = "Darwin" ]; then
        return 0
    else
        return 1
    fi
}

is_travis(){
    if [ -n "${TRAVIS:-}" ]; then
        return 0
    else
        return 1
    fi
}

if is_travis; then
    #export DOCKER_HOST="${DOCKER_HOST:-localhost}"
    HOST="${HOST:-localhost}"
fi

if is_travis; then
    sudo=sudo
else
    sudo=""
fi

# useful for cutting down on number of noisy docker tests which take a long time but more importantly
# cause the CI builds to fail with job logs > 4MB
travis_sample(){
    if is_travis; then
        if [ "$(($RANDOM % 2))" != 0 ]; then
            return 1
        fi
    fi
    return 0
}
