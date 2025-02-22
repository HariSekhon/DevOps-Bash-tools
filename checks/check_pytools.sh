#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2016-09-23 09:16:45 +0200 (Fri, 23 Sep 2016)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir2="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/utils.sh
. "$srcdir2/lib/utils.sh"

# shellcheck source=lib/docker.sh
. "$srcdir2/lib/docker.sh"

srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -z "${PROJECT:-}" ]; then
    export PROJECT=bash-tools
fi

section "DevOps Python Tools Checks"

# must be up here before skipping check so that Dockerfiles can import it
export PATH="$PATH:$srcdir/pytools_checks:$srcdir/../pytools"

start_time="$(start_timer)"

skip_checks=0
if [ "$PROJECT" = "pytools" ]; then
    echo "detected running in pytools repo, skipping checks here as will be called in bash-tools/check_all.sh..."
    skip_checks=1
#elif [ "$PROJECT" = "Dockerfiles" ]; then
#    echo "detected running in Dockerfiles repo, skipping checks here as will be called in bash-tools/check_all.sh..."
#    skip_checks=1
elif is_inside_docker; then
    echo "detected running inside Docker, skipping pytools checks"
    skip_checks=1
fi

if [ $skip_checks = 1 ]; then
    # shellcheck disable=SC2317
    return 0 &>/dev/null ||
    exit 0
fi

echo -n "running on branch:  "
git branch | grep '^\*'
echo
echo "running in dir:  $PWD"
echo

get_pytools(){
    if [ -f "$srcdir/pytools_checks/Makefile" ]; then
        pushd "$srcdir/pytools_checks"
        NOJAVA=1 make update
        popd
    else
        pushd "$srcdir"
        rm -fr -- pytools_checks
        git clone https://github.com/harisekhon/pytools pytools_checks
        pushd pytools_checks
        NOJAVA=1 make
        popd
        popd
    fi
}

validate_yaml_path="$(which validate_yaml.py || :)"

# Ensure we have these at the minimum, these validate_*.py will cover
# most configuration files as we dynamically find and call any validation programs further down
if [[ -z "$validate_yaml_path" || "$validate_yaml_path" =~ pytools_checks ]]; then
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
for validate_program in "$pytools_dir"/validate_*.py; do
    [[ "$validate_program" =~ validate_multimedia.py ]] && continue
    [ -L "$validate_program" ] && continue
    if ! python -V 2>&1 | grep -q 'Python 2' &&
      [[ "$validate_program" =~ validate_cson.py ]]; then
        echo "Skipping validate_cson.py on Python 3+ because the cson module hasn't been ported yet"
        echo
        continue
    fi
    if [[ -n "${SKIP_PARQUET:-}" && "$validate_program" =~ .*parquet.* ]]; then
        echo "Skipping Parquet checks..."
        echo
        continue
    fi
    opts=""
    if [ "${validate_program##*/}" = "validate_ini.py" ] ||
       [ "${validate_program##*/}" = "validate_properties.py" ]; then

        # upstream zookeeper log4j.properties has duplicate keys in it's config
        echo "$validate_program --include 'zookeeper-.*/.*contrib/rest/conf/log4j\\.properties' --ignore-duplicate-keys ."
        $validate_program --include 'zookeeper-.*/.*contrib/rest/conf/log4j\.properties' --ignore-duplicate-keys .
        echo

        # alluxio-site.properies is commented out in Dockerfiles repo due to Alluxio parsing bug
        # gradle's cache.properties is often empty just a single commented date line
        echo "$validate_program --include 'alluxio-site.properties|\\.gradle/.+/taskArtifacts/cache\\.properties' --allow-empty ."
        $validate_program --include 'alluxio-site.properties|\.gradle/.+/taskArtifacts/cache\.properties' --allow-empty .
        echo

        # exclude all of the above which are checked separately with different rules
        # exclude kafka nagios plugin's /target/resolution-cache/check_kafka/check_kafka_2.10/0.1.0/resolved.xml.properties
        # do not quote --exclude arg - the quotes will be interpreted literally and would require an eval
        opts=' --exclude zookeeper-.*/.*contrib/rest/conf/log4j\.properties|\.xml\.properties|alluxio-site.properties|\.gradle/.+/taskArtifacts/cache\.properties|\.gradle/.+/gc.properties'

    fi
    echo "${validate_program}$opts: "
    #  shellcheck disable=SC2086
    ${validate_program}$opts .
    echo
done

time_taken "$start_time"
section2 "DevOps Python Tools validations SUCCEEDED"
echo
