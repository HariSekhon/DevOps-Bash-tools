#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-04-15 13:09:19 +0100 (Wed, 15 Apr 2020)
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
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/../lib/utils.sh"

check_env_defined SEMAPHORE_CI_TOKEN
check_env_defined SEMAPHORE_CI_ORGANIZATION

curl https://storage.googleapis.com/sem-cli-releases/get.sh | bash

sem connect "${SEMAPHORE_CI_ORGANIZATION}".semaphoreci.com "$SEMAPHORE_CI_TOKEN"

echo
echo "Done"
echo
echo "Semaphore CI CLI installed"
echo
sem version
echo
echo "Run 'sem help' for options"
