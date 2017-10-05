#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2016-09-23 09:16:45 +0200 (Fri, 23 Sep 2016)
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
srcdir2="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

. "$srcdir2/utils.sh"

srcdir="$srcdir2"

if [ -z "${PROJECT:-}" ]; then
    export PROJECT=bash-tools
fi

section "PyTools Checks"

skip_checks=0
if [ "$PROJECT" = "pytools" ]; then
    echo "detected running in pytools repo, skipping checks here as will be called in bash-tools/all.sh..."
    skip_checks=1
elif [ "$PROJECT" = "Dockerfiles" ]; then
    echo "detected running in Dockerfiles repo, skipping checks here as will be called in bash-tools/all.sh..."
    skip_checks=1
fi

if [ $skip_checks = 1 ]; then
    return 0 &>/dev/null || :
    exit 0
fi

export PATH="$PATH:$srcdir/pytools_checks:$srcdir/../pytools"

start_time="$(start_timer)"

echo -n "running on branch:  "
git branch | grep ^*
echo
echo "running in dir:  $PWD"
echo

get_pytools(){
    if [ -d "$srcdir/pytools_checks" ]; then
        pushd "$srcdir/pytools_checks"
        make update
        popd
    else
        pushd "$srcdir"
        git clone https://github.com/harisekhon/pytools pytools_checks
        pushd pytools_checks
        make
        popd
        popd
    fi
}

validate_yaml_path="$(which validate_yaml.py || :)"

# Ensure we have these at the minimum, these validate_*.py will cover
# most configuration files as we dynamically find and call any validation programs further down
if [ -z "$validate_yaml_path" ]; then
    get_pytools
fi

echo
echo "Running validation programs:"
echo
validate_yaml_path="$(which validate_yaml.py || :)"
if [ -z "$validate_yaml_path" ]; then
    echo "Failed to find validate_yaml.py in \$PATH ($PATH)"
    exit 1
fi
pytools_dir="$(dirname "$validate_yaml_path")"
for x in "$pytools_dir"/validate_*.py; do
    [[ "$x" =~ validate_multimedia.py ]] && continue
    [ -L "$x" ] && continue
    opts=""
    if [ "${x##*/}" = "validate_ini.py" -o "${x##*/}" = "validate_properties.py" ]; then
        # upstream zookeeper log4j.properties has duplicate keys in it's config
        # if the arg is quoted then would have to eval $x$opts below to get the quotes to be interpreted properly by shell rather than --exclude
        opts=" --exclude zookeeper-.*/.*contrib/rest/conf/log4j.properties"
    fi
    echo "$x$opts: "
    $x$opts .
    echo
done

time_taken "$start_time"
section2 "PyTools validations SUCCEEDED"
echo
