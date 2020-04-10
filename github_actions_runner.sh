#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-04-08 22:15:59 +0100 (Wed, 08 Apr 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

VERSION="${GITHUB_ACTIONS_RUNNER_VERSION:-${GITHUB_ACTIONS_VERSION:-${VERSION:-2.168.0}}}"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC1090
. "$srcdir/.bash.d/git.sh"

check_env_defined GITHUB_ACTIONS_RUNNER_TOKEN

github_repo="${GITHUB_ACTIONS_REPO:-}"
if [ -z "$github_repo" ]; then
    echo "GITHUB_ACTIONS_REPO not defined, inferring from local repository"
    github_repo_url="$(git remote -v | awk '/github/{print $2}' | head -n 1 | git_repo_strip)"
fi

help_usage

cd "$srcdir"

dir=".github_actions_runner"

mkdir -pv "$dir"

cd "$dir"

os="$(uname -s | tr '[:upper:]' '[:lower:]')"
if [ "$os" = darwin ]; then
    os=osx
fi

tar="actions-runner-$os-x64-$VERSION.tar.gz"

if ! [ -f "$tar" ]; then
    url="https://github.com/actions/runner/releases/download/v$VERSION/actions-runner-$os-x64-$VERSION.tar.gz"
    curl -O -L "$url"
fi

if ! [ -f config.sh ]; then
    tar xzf "$tar"
fi

if ! [ -f .credentials ] ||
   ! [ -f .runner ]; then
    ./config.sh remove || :
    yes "" | ./config.sh --url "$github_repo_url" --token "$GITHUB_ACTIONS_RUNNER_TOKEN"
fi

./run.sh
