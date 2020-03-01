#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-01 21:01:50 +0000 (Sun, 01 Mar 2020)
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
srcdir="$(dirname "$0")"

# shellcheck disable=SC1090
source "$srcdir/../lib/utils.sh"

curl_opts=""
if is_CI; then
    curl_opts="-sS"
fi

if is_linux; then
    echo "downloading latest stable version of wercker for Linux..."
    curl $curl_opts -L https://s3.amazonaws.com/downloads.wercker.com/cli/stable/linux_amd64/wercker -o ~/bin/wercker.tmp
elif is_mac; then
    echo "downloading latest stable version of wercker for Mac..."
    curl $curl_opts -L https://s3.amazonaws.com/downloads.wercker.com/cli/stable/darwin_amd64/wercker -o ~/bin/wercker.tmp
else
    echo "OS is not Linux / Mac, not installing wercker CLI"
    exit 0
fi

unalias mv &>/dev/null || :

mv -vf ~/bin/wercker{.tmp,}

chmod -v u+x ~/bin/wercker
