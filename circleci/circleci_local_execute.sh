#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-10 14:51:52 +0000 (Tue, 10 Mar 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Runs Circle CI build locally in Docker
#
# .circleci/config.yml should contain a docker image and not default machine
#
# see local .circleci/config.yml for example

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
#. "$srcdir/lib/utils.sh"

usage(){
    echo "usage: ${0##*/} <job_name>"
    exit 3
}

if ! type -P circleci &>/dev/null; then
    "$srcdir/../install/install_circleci.sh"
fi

if [ $# -gt 1 ]; then
    usage
fi

job_name="${1:-build}"

circleci config process .circleci/config.yml > process.yml
exec circleci local execute -c process.yml --job "$job_name"
