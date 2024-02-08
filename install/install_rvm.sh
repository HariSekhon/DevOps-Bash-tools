#!/bin/sh
#
#  Author: Hari Sekhon
#  Date: 2019-10-04 16:36:18 +0100 (Fri, 04 Oct 2019)
#        (circa 2016 originally)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying LICENSE file
#
#  https://www.linkedin.com/in/HariSekhon
#

# Installs Ruby RVM

set -eu
[ -n "${DEBUG:-}" ] && set -x

if type apk >/dev/null 2>&1; then
    apk --no-cache add bash curl procps
elif type apt-get >/dev/null 2>&1; then
    apt-get update
    apt-get install -y curl procps
elif type yum >/dev/null 2>&1; then
    echo "rhel based systems aleady have curl"
fi

exec bash <<EOF

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB

curl -sSL https://get.rvm.io | bash -s stable --rails

EOF
