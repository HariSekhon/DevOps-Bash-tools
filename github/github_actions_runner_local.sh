#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-04-08 22:15:59 +0100 (Wed, 08 Apr 2020)
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

# shellcheck disable=SC1090,SC1091
. "$srcdir/.bash.d/git.sh"

# shellcheck disable=SC2034
usage_description="
Downloads, configures and runs GitHub Actions Runner to run on the local machine

# XXX: WARNING: GitHub advises self-hosted runners only be used for Private repos to prevent arbitrary code execution on your runners via Pull Requests (or you can set 'Allow local actions only' in the Actions Runners configuration in the repo or org)

Repo URL can be supplied via \$GITHUB_ACTIONS_REPO, otherwise attempts to infer from the local checkout's git remote url

Token can be supplied as either first argument or via environment variable \$GITHUB_ACTIONS_RUNNER_TOKEN

Version can be specified via the environment variable \$GITHUB_ACTIONS_RUNNER_VERSION
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<GITHUB_ACTIONS_RUNNER_TOKEN>]"

help_usage "$@"

VERSION="${GITHUB_ACTIONS_RUNNER_VERSION:-${GITHUB_ACTIONS_VERSION:-${VERSION:-2.284.0}}}"

GITHUB_ACTIONS_RUNNER_TOKEN="${1:-${GITHUB_ACTIONS_RUNNER_TOKEN:-}}"

check_env_defined GITHUB_ACTIONS_RUNNER_TOKEN

github_repo="${GITHUB_ACTIONS_REPO:-}"
if [ -z "$github_repo" ]; then
    echo "GITHUB_ACTIONS_REPO not defined, inferring from local repository"
    github_repo_url="$(git remote -v | awk '/github/{print $2}' | head -n 1 | git_repo_strip_auth)"
    if [ -z "$github_repo_url" ]; then
        echo "Failed to infer github repo url from local git repository"
        exit 1
    fi
    github_repo_url="${github_repo_url#ssh://}"
    github_repo_url="${github_repo_url/://}"
    if ! [[ "$github_repo_url" =~ https?:// ]]; then
        github_repo_url="https://$github_repo_url"
    fi
    echo "inferred github repo url as: $github_repo_url"
fi

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
    tar xzf "$tar" || rm -fv -- "$tar"
fi

if ! [ -f .credentials ] ||
   ! [ -f .runner ]; then
    ./config.sh remove || :
    set +o pipefail
    yes "" | ./config.sh --url "$github_repo_url" --token "$GITHUB_ACTIONS_RUNNER_TOKEN"
fi

./run.sh
