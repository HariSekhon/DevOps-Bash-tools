#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-15 11:52:44 +0100 (Sat, 15 Aug 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/utils.sh
. "$srcdir/lib/utils.sh"

vagrantfiles="$(find "${1:-.}" -maxdepth 3 -name Vagrantfile)"

if [ -z "$vagrantfiles" ]; then
    return 0 &>/dev/null || :
    exit 0
fi

section "V a g r a n t"

start_time="$(start_timer)"

# catches $VAGRANT_HOME/Vagrantfile instead of validating the one we are targeting
unset VAGRANT_HOME

if type -P vagrant &>/dev/null; then
    type -P vagrant
    vagrant --version
    echo
    echo "Validating Vagrantfiles:"
    echo
    while read -r vagrantfile; do
        pushd "$(dirname "$vagrantfile")" >/dev/null

        # create host directories to avoid this Vagrantfile validation error in GitHub Actions "CI Mac" builds:
        #
        # vm:
        # * The host path of the shared folder is missing: ~/github
        #
        awk '/^[[:space:]]*config.vm.synced_folder/{print$2}' Vagrantfile |
        sed 's/,$//; s/"//g' |
        sed "s/'//" |
        while read -r directory; do
            # Mac is silent even with -v and
            # creates literal ~/ subdirectory path unless eval'd, leaving validation to fail with the real path missing
            eval mkdir -p -v "$directory"
        done

        echo -n "$vagrantfile => "
        vagrant validate
        popd >/dev/null
    done <<< "$vagrantfiles"
else
    echo "WARNING: 'vagrant' is not installed, skipping..."
    echo
    exit 0
fi

time_taken "$start_time"
section2 "Vagrantfile validation SUCCEEDED"
echo
