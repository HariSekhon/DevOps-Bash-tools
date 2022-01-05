#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: 1.6.1
#  args:
#
#  Author: Hari Sekhon
#  Date: 2022-01-05 18:51:40 +0000 (Wed, 05 Jan 2022)
#
#  https://github.com/HariSekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "${BASH_SOURCE[0]}")"

# shellcheck disable=SC1090
. "$srcdir/../lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Installs Cert Manager CLI 'cmctl'
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<version>]"

help_usage "$@"

#min_args 1 "$@"

version="${1:-latest}"

if [ "$version" != latest ] &&
   ! [[ "$version" =~ ^v ]]; then
    version="v$version"
fi

if [ "$version" = latest ]; then
    "$srcdir/../install_binary.sh" "https://github.com/jetstack/cert-manager/releases/latest/download/cmctl-{os}-{arch}.tar.gz" cmctl
else
    "$srcdir/../install_binary.sh" "https://github.com/jetstack/cert-manager/releases/download/$version/cmctl-{os}-{arch}.tar.gz" cmctl
fi
