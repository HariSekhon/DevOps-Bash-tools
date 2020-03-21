#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-19 19:21:31 +0000 (Thu, 19 Mar 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Start a quick local Concourse CI

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

config="$srcdir/setup/concourse_quickstart.yml"

target="ci"

pipeline="${PWD##*/}"
job="$pipeline/build"

if ! type docker-compose &>/dev/null; then
    "$srcdir/install_docker_compose.sh"
fi

action="${1:-up}"
shift || :

opts=""
if [ "$action" = up ]; then
    opts="-d"
fi

if ! [ -f "$config" ]; then
    wget -O "$config" https://concourse-ci.org/docker-compose.yml
fi

docker-compose -f "$config" "$action" $opts "$@"
echo

export PATH="$PATH:"~/bin

when_url_content 'http://127.0.0.1:8080/' '(?i:concourse)' # Concourse
echo

# which checks for executable which command -v and type -P don't
# shellcheck disable=SC2230
if [ "$action" = up ] &&
   ! which fly &>/dev/null; then
    dir=~/bin
    mkdir -pv "$dir"
    os="$(uname -s | tr '[:upper:]' '[:lower:]')"
    echo "Downloading fly for OS = $os"
    wget -cO "$dir/fly" "http://127.0.0.1:8080/api/v1/cli?arch=amd64&platform=$os"
    chmod +x "$dir/fly"
    echo
fi

fly -t "$target" login -c http://127.0.0.1:8080 -u test -p test
echo

echo "updating pipeline: $pipeline"
# fly sp
fly -t "$target" set-pipeline -p "$pipeline" -c .concourse.yml
echo

echo "unpausing pipeline: $pipeline"
# fly up
fly -t "$target" unpause-pipeline -p "$pipeline"
echo

echo "unpausing job: $job"
# fly uj
fly -t "$target" unpause-job --job "$job"

#fly -t "$target" trigger-job -j "$job"
#fly -t "$target" watch -j "$job"

# trigger + watch together
fly -t "$target" trigger-job -j "$job" -w

echo
fly -t "$target" builds
