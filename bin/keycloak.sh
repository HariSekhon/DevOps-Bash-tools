#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-03-09 17:05:31 +0000 (Wed, 09 Mar 2022)
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
. "$srcdir/lib/git.sh"

# shellcheck disable=SC2034
usage_description="
Boots Keycloak in Docker

- boots Keycloak container in Docker
- configures admin user
- prints admin credentials
- prints Keycloak UI URL and opens it in browser

    ${0##*/} [up]

    ${0##*/} down

    ${0##*/} ui     - prints the KeycloakServer URL and automatically opens in browser

Idempotent, you can re-run this and continue from any stage
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[ up | down | ui ]"

help_usage "$@"

export KEYCLOAK_HOST="${DOCKER_HOST:-localhost}"
export KEYCLOAK_PORT=8080

export KEYCLOAK_URL="http://$KEYCLOAK_HOST:$KEYCLOAK_PORT/admin"

export COMPOSE_PROJECT_NAME="bash-tools"
export COMPOSE_FILE="$srcdir/../docker-compose/keycloak.yml"

if ! type docker-compose &>/dev/null; then
    "$srcdir/../install/install_docker_compose.sh"
fi

action="${1:-up}"
shift || :

if [ "$action" = up ]; then
    timestamp "Booting Keycloak:"
    docker-compose up -d "$@"
    echo >&2
elif [ "$action" = restart ]; then
    docker-compose down
    echo >&2
    exec "${BASH_SOURCE[0]}" up
elif [ "$action" = ui ]; then
    echo
    echo "Keycloak URL:  $KEYCLOAK_URL"
    echo
    echo "Keycloak user: ${KEYCLOAK_ADMIN:-admin}"
    echo "Keycloak password: ${KEYCLOAK_ADMIN_PASSWORD:-admin}"
    echo
    open "$KEYCLOAK_URL"
    exit 0
else
    docker-compose "$action" "$@"
    echo >&2
    exit 0
fi

when_url_content 90 "$KEYCLOAK_URL" '(?i:keycloak)'

exec "$0" ui
