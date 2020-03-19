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

config="$srcdir/concourse_quickstart.yml"

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

export PATH="$PATH:"~/bin

# which checks for executable which command -v and type -P don't
# shellcheck disable=SC2230
if [ "$action" = up ] &&
   ! which fly &>/dev/null; then
    when_url_content 'http://127.0.0.1:8080/' '(?i:concourse)' # Concourse
    dir=~/bin
    mkdir -pv "$dir"
    os="$(uname -s | tr '[:upper:]' '[:lower:]')"
    echo "Downloading fly for OS = $os"
    wget -cO "$dir/fly" "http://127.0.0.1:8080/api/v1/cli?arch=amd64&platform=$os"
    chmod +x "$dir/fly"
fi

fly -t ci login -c http://127.0.0.1:8080 -u test -p test

fly -t ci set-pipeline -p "${PWD##*/}" -c .concourse.yml
