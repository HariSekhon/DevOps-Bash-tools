#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2016-01-15 00:33:52 +0000 (Fri, 15 Jan 2016)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/utils.sh
. "$srcdir/lib/utils.sh"

# shellcheck source=lib/docker.sh
. "$srcdir/lib/docker.sh"

#return 0 &>/dev/null || :
#exit 0

section "Travis CI Yaml Lint Check"

if ! [ -f .travis.yml ]; then
    echo "No .travis.yml found, skipping Travis CI check"
    exit 0
fi

start_time="$(start_timer)"

#if is_travis; then
#    echo "Running inside Travis CI, skipping lint check"
if is_inside_docker; then
    echo "Running inside Docker, skipping Travis lint check"
else
    # sometimes ~/.gem/ruby/<version>/bin may not be in $PATH but this succeeds anyway if hashed in shell
    #if ! type travis &>/dev/null; then
    for path in ~/.gem/ruby/*/bin; do
        [ -d "$path" ] || continue
        echo "adding $path to \$PATH"
        export PATH="$PATH:$path"
    done
    if ! type -P travis &>/dev/null; then
        ruby_version="$(ruby --version | awk '{print $2}' | grep -Eo '[[:digit:]]+\.[[:digit:]]+' | head -n1)"
        if bc -l <<< "$ruby_version < 2.4" | grep -q 1; then
            echo "Ruby version is < 2.4, too old to install Travis CI gem, skipping check"
        elif type -P gem &>/dev/null; then
            # this returns ruby-1.9.3 but using 1.9.1
            #ruby_version="$(ruby --version | awk '{print $2}' | sed 's/p.*//')"
            #export PATH="$PATH:$HOME/.gem/ruby/$ruby_version/bin"
            echo "installing travis gem... (requires ruby-dev package to be installed)"
            # --no-rdoc option not valid on GitHub Workflows macos-latest build
            #gem install --user-install travis --no-rdoc --no-ri
            #"$srcdir/ruby_gem_install_if_absent.sh" travis
            # handles SSL linking issues on Mac
            NONINTERACTIVE=1 "$srcdir/../install/install_travis.sh"
            for path in ~/.gem/ruby/*/bin; do
                [ -d "$path" ] || continue
                echo "adding $path to \$PATH"
                export PATH="$PATH:$path"
            done
        else
            echo "WARNING: skipping Travis install as gem command was not found in \$PATH"
        fi
        echo
    fi
    if type -P travis &>/dev/null; then
        echo 'Travis path:'
        echo
        type -P travis
        echo
        echo -n 'Travis version:  '
        if ! travis version --no-interactive; then
            echo
            echo "WARNING: Travis Gem / install broken, skipping check"
            exit 1
        fi
        echo
        echo -n 'Travis lint:  '
        # Travis CI is getting upstream errors randomly, eg.
        # server error (500: "Sorry, we experienced an error.\n\nrequest_id:16146a4f-677e-4314-888d-149617bdae2d\n")
        set +e
        if is_CI; then
            # get past shell completion install prompt in CI
            #echo "n" | travis lint
            travis lint --no-interactive
        else
            travis lint
        fi
        set -e
    else
        echo "WARNING: skipping Travis check as Travis is not installed"
    fi
fi

echo
time_taken "$start_time"
section2 "Travis CI yaml validation succeeded"
echo
