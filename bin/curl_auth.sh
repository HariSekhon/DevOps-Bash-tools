#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-01-02 21:08:12 +0000 (Wed, 02 Jan 2019)
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

# used by utils.sh usage()
# shellcheck disable=SC2034
usage_description="
Runs curl with either Kerberos SpNego (if \$KRB5 is set) or a ram file descriptor using \$PASSWORD or \$TOKEN to avoid credentials being exposed via process list or command line logging

Requires prefixing url with http:// or https:// to work on older versions of curl in order to parse hostname
for constructing the authentication string to be specific to the host as using netrc default login doesn't always work
"


# shellcheck source=lib/utils.sh disable=SC1091
. "$srcdir/lib/utils.sh"

# used by utils.sh usage()
# shellcheck disable=SC2034
usage_args="[<curl_options>] <url>"

if [ $# -lt 1 ]; then
    # shellcheck disable=SC2119
    usage
fi

for x in "$@"; do
    # shellcheck disable=SC2119
    case "$x" in
        -h|--help) usage
        ;;
    esac
done

check_bin curl

USERNAME="${USERNAME:-${USER:-$(whoami)}}"
# for APIs like Codeship codeship_api_token.sh in which you must use basic auth and not pass a token
if [ -z "${NO_TOKEN_AUTH:-}" ]; then
    TOKEN="${TOKEN:-${OAUTH2_TOKEN:-${OAUTH_TOKEN:-${JWT_TOKEN:-}}}}"
fi

# Only do password mechanism and netrc_contents workaround if not using Kerberos
if [ -z "${KRB5:-${KERBEROS:-}}" ]; then
    if is_blank "${PASSWORD:-}" &&
       is_blank "${TOKEN:-}"; then
        pass
    fi

    # ==============================================
    # option 1

    # needs newer version of curl, otherwise fall back to parsing the hostname and dynamically created netrc contents
    # curl 7.64.1 (x86_64-apple-darwin19.0) libcurl/7.64.1 (SecureTransport) LibreSSL/2.8.3 zlib/1.2.11 nghttp2/1.39.2
    # curl 7.35.0 (x86_64-pc-linux-gnu) libcurl/7.35.0 OpenSSL/1.0.1f zlib/1.2.8 libidn/1.28 librtmp/2.3
    if is_blank "${TOKEN:-}" &&
       is_curl_min_version 7.64; then
        netrc_contents="default login $USERNAME password $PASSWORD"
    fi

    # ==============================================
    # option 2
    #
    #hosts="$(awk '{print $1}' < ~/.ssh/known_hosts 2>/dev/null | sed 's/,.*//' | sort -u)"

    # use built-in echo if availble, cat is slow with ~1000 .ssh/known_hosts
    #if help echo &>/dev/null; then
    #    netrc_contents="$(for host in $hosts; do echo "machine $host login $USERNAME password $PASSWORD"; done)"
    #else
    #    # slow fallback with lots of forks
    #    netrc_contents="$(for host in $hosts; do cat <<< "machine $host login $USERNAME password $PASSWORD"; done)"
    #fi

    # ==============================================
    # option 3

    # Instead of generating this for all known hosts above just do it for the host extracted from the args url now

    if is_blank "${TOKEN:-}" &&
       [ -z "${netrc_contents:-}" ]; then
        if ! [[ "$*" =~ :// ]]; then
            usage "http(s):// not specified in URL"
        fi

        # sed https* - because sed on Mac doesn't respect either ? or \? and otherwise I'd have to use:
        #
        # perl -pe 's/https?:\/\///'
        #
        # or else wrap
        #
        # if is_mac; then
        #       sed(){ gsed "$@" }
        # fi
        #
        host="$(grep -Eom 1 'https?://[^:\/[:space:]]+' <<< "$*" | sed 's,https*://,,' | head -n1)"

        netrc_contents="machine $host login $USERNAME password $PASSWORD"
    fi
fi

# ==============================================

if [ -n "${KRB5:-${KERBEROS:-}}" ]; then
    command curl -u : --negotiate "$@"
elif ! is_blank "${TOKEN:-${JWT_TOKEN:-}}"; then
    if ! is_blank "${JWT_TOKEN:-}"; then
        auth_header="${CURL_AUTH_HEADER:-Authorization: JWT} $JWT_TOKEN"
    else
        # OAuth2
        auth_header="${CURL_AUTH_HEADER:-Authorization: Bearer} $TOKEN"
    fi
    if is_curl_min_version 7.55; then
        # this trick doesn't work, file descriptor is lost by next line
        #filedescriptor=<(cat <<< "Private-Token: $GITLAB_TOKEN")
        command curl -H @<(cat <<< "$auth_header") "$@"
    else
        command curl -H "$auth_header" "$@"
    fi
else
    command curl --netrc-file <(cat <<< "$netrc_contents") "$@"
fi
