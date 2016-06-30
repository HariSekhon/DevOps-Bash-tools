#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2016-01-15 00:33:52 +0000 (Fri, 15 Jan 2016)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

return 0 &>/dev/null || :
exit 0
if [ -z "${TRAVIS:-}" ]; then
    which travis &>/dev/null ||
        gem install travis --no-rdoc --no-ri
    yes "y" | travis lint
fi
echo "Travis validation succeeded"
echo
