#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-06-24 01:17:21 +0100 (Wed, 24 Jun 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
#usage_args="arg [<options>]"

# shellcheck disable=SC2034
usage_description="
Returns spotify playlists for \$SPOTIFY_USER / \$USER
"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

user="${SPOTIFY_USER:-${USER:-whoami}}"

"$srcdir/spotify_api.sh" "/v1/users/$user/playlists?limit=50"
