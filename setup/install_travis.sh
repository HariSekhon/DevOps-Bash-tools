#!/usr/bin/env bash
#
#  Author: Hari Sekhon
#  Date: 2019-09-17
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

gem install --user-install travis

# add ruby to paths temporarily (logic borrowed from advanced bashrc code in .bash.d/paths.sh)
for ruby_bin in $(find ~/.gem/ruby -maxdepth 2 -name bin -type d 2>/dev/null | tail -r); do
    export PATH="$PATH:$ruby_bin"
done

travis login
travis token
