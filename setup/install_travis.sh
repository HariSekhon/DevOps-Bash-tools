#!/usr/bin/env bash
#
#  Author: Hari Sekhon
#  Date: Tue Sep 17 16:41:02 2019 +0100
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying LICENSE file
#
#  https://www.linkedin.com/in/HariSekhon
#

# Installs the Travis CI gem to home dir, logs in and generates a $TRAVIS_TOKEN
#
# putting the $TRAVIS_TOKEN in your environment is useful for the travis tools available in
#
#  https://github.com/HariSekhon/DevOps-Python-tools

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/../lib/ci.sh"

# shellcheck disable=SC1090,SC1091
. "$srcdir/../lib/os.sh"

# fix version of Travis CI since it has a dependency on SSL and we need to detect and switch the SSL version for certain Mac environments, eg. Semaphore CI
export GEM_OPTS="-v 1.8.13"

if is_mac; then
    #if ! [ -f /usr/local/opt/openssl/lib/libssl.1.0.0.dylib ]; then
    if is_semaphore_ci; then
        echo "Switching OpenSSL to version 1.0.2t on Mac to avoid SSL build errors for Travis CI gem" >&2
        #brew switch openssl 1.0.2t
        brew reinstall ruby
    fi
fi

"$srcdir/../packages/ruby_gem_install_if_absent.sh" travis

# add ruby to paths temporarily (logic borrowed from advanced bashrc code in .bash.d/paths.sh)
for ruby_bin in $(find ~/.gem/ruby -maxdepth 2 -name bin -type d 2>/dev/null | tac); do
    export PATH="$PATH:$ruby_bin"
done

if ! is_CI &&
   [ -z "${QUICK:-}" ] &&
   [ -z "${NONINTERACTIVE:-}" ]; then
    travis login
    travis token
fi
