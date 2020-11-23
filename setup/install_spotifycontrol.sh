#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-11-17 11:28:16 +0000 (Tue, 17 Nov 2020)
#
#  https://github.com/HariSekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Update: using Shpotify now which is installed via adjacent brew packages list

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

curl -sS https://raw.githubusercontent.com/dronir/SpotifyControl/master/SpotifyControl > /tmp/spotify
chmod -v +x /tmp/spotify
mv -v /tmp/spotify ~/bin
