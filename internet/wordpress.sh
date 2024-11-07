#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2023-12-04 12:21:15 +0000 (Mon, 04 Dec 2023)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://hub.docker.com/_/wordpress

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# dipping into interactive library for opening browser to Wordpress
# XXX: order is important here because there is an interactive library of retry() and a scripting library version of retry() and we want the latter, which must be imported second
# shellcheck disable=SC1090,SC1091
. "$srcdir/../.bash.d/network.sh"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

export WORDPRESS_URL="http://${DOCKER_HOST:-localhost}:8080"
export COMPOSE_PROJECT_NAME="bash-tools"
export DOCKER_CONTAINER="$COMPOSE_PROJECT_NAME-wordpress-1"
export COMPOSE_FILE="$srcdir/../docker-compose/wordpress.yml"
export WORDPRESS_HTACCESS_FILE="$srcdir/wordpress.htaccess"
export WORDPRESS_HTACCESS_PATH="/var/www/html/.htaccess"

# shellcheck disable=SC2034,SC2154
usage_description="
Boots a quick Wordpress blog container

Copies .htaccess settings from the adjacent file to increase upload sizes for restoring backups:

    $WORDPRESS_HTACCESS_FILE

Opens the Wordpress URL in the default browser:

    $WORDPRESS_URL

To boot a specific version of Wordpress:

export VERSION=6.4

Note some plugins will break the Live Preview of themes and must be temporarily deactivated to see them, such as:

Antispam Bee
Broken Link Checker
Jetpack Boost
IONOS Security
Yoast SEO plugin

Tested on Wordpress 6.4
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[ up | down | ui ]"

help_usage "$@"

if ! type docker-compose &>/dev/null; then
    "$srcdir/../install/install_docker_compose.sh"
fi

action="${1:-up}"
shift || :

if [ "$action" = up ]; then
    timestamp "Booting Wordpress:"
    docker-compose up -d "$@"
    echo
    when_url_content 60 "$WORDPRESS_URL" '.*'
    echo
    timestamp "Copying $WORDPRESS_HTACCESS_FILE into wordpress container $WORDPRESS_HTACCESS_PATH"
    docker cp "$WORDPRESS_HTACCESS_FILE" "$DOCKER_CONTAINER":"$WORDPRESS_HTACCESS_PATH"
    echo
    exec "${BASH_SOURCE[0]}" ui
elif [ "$action" = restart ]; then
    docker-compose down
    echo
    exec "${BASH_SOURCE[0]}" up
elif [ "$action" = ui ]; then
    echo "Wordpress URL:  $WORDPRESS_URL"
    open "$WORDPRESS_URL"
else
    docker-compose "$action" "$@"
    echo
fi
