#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-19 19:21:31 +0000 (Thu, 19 Mar 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Start a quick local Concourse CI

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034
usage_description="
Boots Concourse CI in Docker, and builds the current repo

- boots Concourse container in Docker
- creates job pipeline from \$PWD/.concourse.yml
- unpauses pipeline and job
- triggers pipeline job
- follows job build log in CLI
- prints recent build statuses

    ${0##*/} [up]

    ${0##*/} down

    ${0##*/} ui     - prints the Concourse URL and automatically opens in browser

Idempotent, you can re-run this and continue from any stage

See Also:

    fly.sh - wraps the fly command specifying target from the environment variable FLY_TARGET to avoid repetition. Also automatically downloads the 'fly' utility if not present in \$PATH
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[ up | down | ui ]"

help_usage "$@"

export CONCOURSE_USER="${CONCOURSE_USER:-test}"
export CONCOURSE_PASSWORD="${CONCOURSE_PASSWORD:-test}"

export CONCOURSE_HOST=localhost
export CONCOURSE_PORT=8081

protocol="http"
if [ -n "${CONCOURSE_SSL:-}" ]; then
    protocol=https
fi

CONCOURSE_URL="$protocol://$CONCOURSE_HOST:$CONCOURSE_PORT"

export COMPOSE_PROJECT_NAME="bash-tools"
export COMPOSE_FILE="$srcdir/../docker-compose/concourse.yml"

export FLY_TARGET="ci"

pipeline="${PWD##*/}"
job="$pipeline/build"

if ! type docker-compose &>/dev/null; then
    "$srcdir/../install/install_docker_compose.sh"
fi

action="${1:-up}"
shift || :

if ! [ -f "$COMPOSE_FILE" ]; then
    timestamp "downloading Concourse CI docker-compose.yml" # this is in Git so shouldn't run any more
    wget -O "$COMPOSE_FILE" https://concourse-ci.org/docker-compose.yml
fi

if [ "$action" = up ]; then
    timestamp "Booting Concourse:"
    docker-compose up -d "$@"
    echo >&2
elif [ "$action" = restart ]; then
    docker-compose down
    echo >&2
    exec "${BASH_SOURCE[0]}" up
elif [ "$action" = ui ]; then
    echo "Concourse URL:  $CONCOURSE_URL"
    echo
    echo "Concourse user:     $CONCOURSE_USER"
    echo "Concourse password: $CONCOURSE_PASSWORD"
    echo
    open "$CONCOURSE_URL"
    exit 0
else
    docker-compose "$action" "$@"
    echo >&2
    exit 0
fi

export PATH="$PATH:"~/bin

when_url_content "$CONCOURSE_URL" '(?i:concourse)' # Concourse
echo

# done in fly.sh now
# which checks for executable which command -v and type -P don't
# shellcheck disable=SC2230
#if [ "$action" = up ] &&
#   ! which fly &>/dev/null; then
#    # fly.sh has ~/bin in $PATH
#    dir=~/bin
#    mkdir -pv "$dir"
#    os="$(uname -s | tr '[:upper:]' '[:lower:]')"
#    echo "Downloading fly for OS = $os"
#    wget -cO "$dir/fly" "http://$CONCOURSE_HOST:$CONCOURSE_PORT/api/v1/cli?arch=amd64&platform=$os"
#    chmod +x "$dir/fly"
#    echo
#fi

timestamp "fly login:"
"$srcdir/fly.sh" login -c "$CONCOURSE_URL" -u "$CONCOURSE_USER" -p "$CONCOURSE_PASSWORD"
echo

concourse_yml=".concourse.yml"

if ! [ -f "$concourse_yml" ]; then
    timestamp "Concourse configuration file '$concourse_yml' not found"
    echo >&2
    timestamp "Skipping loading missing pipeline"
    echo >&2
    timestamp "Re-run this from the directory containing '$concourse_yml' to auto-load a pipeline"
    exit 0
fi

timestamp "updating pipeline: $pipeline"
timestamp "loading config from $concourse_yml"
# fly sp
set +o pipefail
yes | "$srcdir/fly.sh" set-pipeline -p "$pipeline" -c "$concourse_yml"
set -o pipefail
echo

timestamp "unpausing pipeline: $pipeline"
# fly up
"$srcdir/fly.sh" unpause-pipeline -p "$pipeline"
echo

timestamp "unpausing job: $job"
# fly uj
"$srcdir/fly.sh" unpause-job --job "$job"

#"$srcdir/fly.sh" trigger-job -j "$job"
#"$srcdir/fly.sh" watch -j "$job"

echo
echo "Concourse URL:  $CONCOURSE_URL"
echo

# trigger + watch together
"$srcdir/fly.sh" trigger-job -j "$job" -w

echo
"$srcdir/fly.sh" builds
