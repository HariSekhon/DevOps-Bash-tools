#!/bin/sh
#
#  Author: Hari Sekhon
#  Date: 2019-10-04 16:36:18 +0100 (Fri, 04 Oct 2019)
#        (circa 2016 originally)
#
#  https://github.com/harisekhon/devops-bash-tools
#
#  License: see accompanying LICENSE file
#
#  https://www.linkedin.com/in/harisekhon
#

# Installs Ruby RVM

set -eu
[ -n "${DEBUG:-}" ] && set -x

if type apk >/dev/null; then
    apk --no-cache add bash curl procps
elif type apt-get >/dev/null; then
    apt-get update
    apt-get install -y curl procps
elif type yum >/dev/null; then
    echo "rhel based systems aleady have curl"
fi

exec bash <<EOF

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

curl -sSL https://get.rvm.io | bash -s stable --rails

EOF
