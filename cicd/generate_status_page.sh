#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-02-07 15:01:31 +0000 (Fri, 07 Feb 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Script to generate STATUS.md containing all GitHub repos and DockerHub / Docker Cloud repos build statuses on a single page
#
# uses adjacent github_generate_status_page.sh and docker_generate_status_page.sh scripts
#
#   GITHUB_USER=HariSekhon DOCKER_USER=harisekhon ./generate_status_page.sh

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

trap 'echo ERROR >&2' exit

cd "$srcdir"

file="STATUS.md"

echo
echo "Generating STATUS.md"
echo
{
"$srcdir/../github/github_generate_status_page.sh"
echo
echo "---"
echo
#"$srcdir/../docker/docker_generate_status_page.sh"
echo
echo https://git.io/hari-ci
} | tee "$file"

echo
echo
echo "Generating STARCHARTS.md"
echo
"$srcdir/../github/github_generate_starcharts.md.sh"

trap '' exit
