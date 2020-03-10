#!/usr/bin/env bash
#
#  Author: Hari Sekhon
#  Date: Tue Sep 17 16:41:02 2019 +0100
#
#  https://github.com/harisekhon/devops-bash-tools
#
#  License: see accompanying LICENSE file
#
#  https://www.linkedin.com/in/harisekhon
#

# Installs the Travis CI gem to home dir, logs in and generates a $TRAVIS_TOKEN
#
# putting the $TRAVIS_TOKEN in your environment is useful for the travis tools available in
#
#  https://github.com/harisekhon/devops-python-tools

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

"$srcdir/../ruby_gem_install_if_absent.sh" travis

# add ruby to paths temporarily (logic borrowed from advanced bashrc code in .bash.d/paths.sh)
for ruby_bin in $(find ~/.gem/ruby -maxdepth 2 -name bin -type d 2>/dev/null | tail -r); do
    export PATH="$PATH:$ruby_bin"
done

if [ -z "${QUICK:-}" ] &&
   [ -z "${NONINTERACTIVE:-}" ]; then
    travis login
    travis token
fi
