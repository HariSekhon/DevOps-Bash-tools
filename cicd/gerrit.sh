#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-07-08 13:22:34 +0100 (Wed, 08 Jul 2020)
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

# shellcheck disable=SC2034
usage_description="
Runs Gerrit via docker-compose/gerrit.yml
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="arg [<options>]"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

GERRIT_VERSION="3.1.3"

gerrit_local(){
    GERRIT_SITE=~/gerrit_site

    WAR="$GERRIT_SITE/gerrit-$GERRIT_VERSION.war"

    help_usage "$@"

    mkdir -pv "$GERRIT_SITE"

    wget -O "$WAR" "https://gerrit-releases.storage.googleapis.com/gerrit-$GERRIT_VERSION.war"

    java -jar "$WAR" init --batch --dev -d "$GERRIT_SITE"

    # restrict to localhost as per best practice
    git config --file "$GERRIT_SITE/etc/gerrit.config" httpd.listenUrl 'http://localhost:8080'

    "$GERRIT_SITE/bin/gerrit.sh" restart
}

gerrit_docker(){
    #docker run -d -ti -p 8080:8080 -p 29418:29418 gerritcodereview/gerrit:"$GERRIT_VERSION"
    VERSION="$GERRIT_VERSION" docker-compose -f "$srcdir/../docker-compose/gerrit.yml" up -d
}

gerrit_docker

if [ "$(uname -s)" = Darwin ]; then
    when_ports_available 120 localhost 8080
    when_url_content 60 'http://localhost:8080' Gerrit
    open 'http://localhost:8080'
fi
