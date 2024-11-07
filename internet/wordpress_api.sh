#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: /users/1 | jq .
#
#  Author: Hari Sekhon
#  Date: 2024-01-23 10:54:30 +0000 (Tue, 23 Jan 2024)
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
. "$srcdir/lib/git.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Queries the Wordpress API v2

Requires WORDPRESS_URL, WORDPRESS_USER and WORDPRESS_PASSWORD environment variables to be defined

Automatically adds the /wp-json/wp/v2/ prefix for convenience


Can specify \$CURL_OPTS for options to pass to curl or provide them as arguments


Set up an application password and export it in the shell environment variable WORDPRESS_PASSWORD

    https://make.wordpress.org/core/2020/11/05/application-passwords-integration-guide/


API Reference:

    https://developer.wordpress.org/rest-api/reference/


To return only a subset of fields add '?fields=field1,field2...' to the /url/path

    https://developer.wordpress.org/rest-api/using-the-rest-api/global-parameters/


You will need to handle pagination in the calling scripts:

    https://developer.wordpress.org/rest-api/using-the-rest-api/pagination/


Examples:


# Get users:

    ${0##*/} /users

    # get a specific user by user id 1
    ${0##*/} /users/1


# Get categories:
                                                   # or .name
    ${0##*/} /categories?per_page=100 | jq -r '.[].slug'


# Get comments:

    ${0##*/} /comments?per_page=100 | jq .

    # get a specific comment
    ${0##*/} /comments/<id>


# Get media (images metadata):

    ${0##*/} /media | jq .


# Get pages:

    ${0##*/} /pages | jq .


# Get posts (articles):

    ${0##*/} /posts | jq .


# Get post revisions:

    ${0##*/} /posts/<id>/revisions | jq .

# Get posts that match a given search term:

    ${0##*/} /search?search=sekhon | jq .

# Get tags:
                                                   # or .name
    ${0##*/} /tags?per_page=100 | jq -r '.[].slug'
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="/path [<curl_options>]"

help_usage "$@"

min_args 1 "$@"

check_env_defined WORDPRESS_URL
check_env_defined WORDPRESS_USER
check_env_defined WORDPRESS_PASSWORD

curl_api_opts "$@"

url_path="$1"
shift || :

url_base="$WORDPRESS_URL"
if ! [[ "$url_base" =~ ^https:// ]] && ! [[ "$url_base" =~ http://localhost[:/] ]]; then
    usage "must use an HTTPS url for WORDPRESS_URL for safety unless using localhost"
fi

# more generic but needless fork
#url_path="$(sed 's|https?://[^/]*' <<< "$url_path")"
#
# not needed, works without this ugly hack
# shellcheck disable=SC2295
#url_path="${url_path##""$WORDPRESS_URL""}"
url_path="${url_path##$WORDPRESS_URL}"

url_path="${url_path##/}"
if [[ "$url_path" =~ /v1/|/wp-site-health/ ]]; then
    WORDPRESS_NO_PREFIX=1
fi
if [ -z "${WORDPRESS_NO_PREFIX:-}" ]; then
    url_path="${url_path##wp-json/}"
    url_path="${url_path##wp/}"
    url_path="${url_path##v2/}"
    url_path="wp-json/wp/v2/$url_path"
fi

export USERNAME="$WORDPRESS_USER"
export PASSWORD="$WORDPRESS_PASSWORD"

# useless it requires ID which is not your $WORDPRESS_USERNAME
#url_path="${url_path/<user_id>/$WORDPRESS_USER}"
#url_path="${url_path/\{user_id\}/$WORDPRESS_USER}"
#url_path="${url_path/<user>/$WORDPRESS_USER}"
#url_path="${url_path/\{user\}/$WORDPRESS_USER}"

"$srcdir/../bin/curl_auth.sh" "$url_base/$url_path" ${CURL_OPTS:+"${CURL_OPTS[@]}"} "$@" |
jq_debug_pipe_dump
