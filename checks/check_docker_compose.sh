#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-01-06 13:43:32 +0000 (Mon, 06 Jan 2020)
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

filelist="$(find "${1:-.}" -type f -iname '*docker-compose*.y*ml' -o -type f -ipath '*/docker-compose/*.y*ml' | sort)"

if [ -z "$filelist" ]; then
    return 0 &>/dev/null ||
    exit 0
fi

section "Docker Compose Syntax Checks"

start_time="$(start_timer)"

if [ -n "${NOSYNTAXCHECK:-}" ]; then
    echo "\$NOSYNTAXCHECK environment variable set, skipping docker-compose syntax checks"
    echo
elif [ -n "${QUICK:-}" ]; then
    echo "\$QUICK environment variable set, skipping docker-compose syntax checks"
    echo
else
    if ! command -v docker-compose &>/dev/null; then
        echo "docker-compose not found in \$PATH, not running syntax checks"
        return 0 &>/dev/null || exit 0
    fi
    docker-compose --version
    echo
    if is_bitbucket_ci; then
        echo 'Docker compose version on BitBucket is too old to validate syntax, skipping...'
        echo
        exit 0
    fi
    max_len=0
    for x in $filelist; do
        if [ "${#x}" -gt "$max_len" ]; then
            max_len="${#x}"
        fi
    done
    # to account for the semi colon
    ((max_len + 1))
    for docker_compose_path in $filelist; do
        isExcluded "$docker_compose_path" && continue
        printf "%-${max_len}s " "$docker_compose_path:"
        docker_compose_dir="$(dirname "$docker_compose_path")"
        docker_compose_basename="${docker_compose_path##*/}"
        pushd "$docker_compose_dir" &>/dev/null
        env=()
        # if there is a matching .env file use it instead of the default, this will fill in missing variables
        if [ -f "${docker_compose_basename%.*}.env" ]; then
            env+=(--env-file "${docker_compose_basename%.*}.env")
        fi
        set +eo pipefail
        output="$(docker-compose -f "$docker_compose_basename" ${env:+"${env[@]}"} config >/dev/null)"
        # shellcheck disable=SC2181
        if [ $? -eq 0 ]; then
            echo "OK"
        else
            echo "FAILED"
            if [ -z "${QUIET:-}" ]; then
                echo
                echo "$output"
                echo
            fi
            if [ -z "${NOEXIT:-}" ]; then
                return 1 &>/dev/null || exit 1
            fi
        fi
        set -eo pipefail
        popd &>/dev/null
    done
    time_taken "$start_time"
    section2 "All docker-compose files passed syntax check"
fi
echo
