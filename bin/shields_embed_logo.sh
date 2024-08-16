#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-08-16 19:53:07 +0200 (Fri, 16 Aug 2024)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
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

# shellcheck disable=SC2034,SC2154
usage_description="
Base64 encodes a given icon file or url and prints the logo=... url parameter you need to add the shields.io badge url

If you pass a URL will download the URL and base64 the content

Otherwise download the icon to your local disk eg. using SimpleIcons.org and pass that as a parameter

This is only tested with svg files at this time

Example:

        wget -nc https://raw.githubusercontent.com/simple-icons/simple-icons/e8de041b64586c0c532f9ea5508fd8e29d850937/icons/linkedin.svg

        ${0##*/} linkedin.svg

    or

        ${0##*/} https://raw.githubusercontent.com/simple-icons/simple-icons/e8de041b64586c0c532f9ea5508fd8e29d850937/icons/linkedin.svg
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<filename_or_url>"

help_usage "$@"

min_args 1 "$@"

icon="$1"

if [[ "$icon" =~ ^https?:// ]]; then
    content="$(curl -sS "$icon")"
elif [ -f "$icon" ]; then
    content="$(cat "$icon")"
else
    usage "first argument needs to be a URL or a local file"
fi

data="$(base64 <<< "$content")"

echo "logo=data:image/svg%2bxml;base64,$data"
