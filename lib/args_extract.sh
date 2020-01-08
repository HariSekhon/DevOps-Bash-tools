#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-12-20 16:01:28 +0000 (Fri, 20 Dec 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback
#
#  https://www.linkedin.com/in/harisekhon
#

# helper script for calling from vim function to run programs with args extraction

set -euo pipefail

sed -n '/^[[:space:]]*#[[:space:]]*args:/ s/^[[:space:]]*#[[:space:]]*args:[[:space:]]// p' "$@"
