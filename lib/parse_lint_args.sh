#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-05-12 11:07:11 +0100 (Thu, 12 May 2022)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback
#
#  https://www.linkedin.com/in/HariSekhon
#

# Helper script for calling from vim function to lint programs
#
# Runs the value of the 'lint:' header from the given file

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
#srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# examples:
#
# #  lint: datree test
perl -ne 'if(/^\s*(#|\/\/|--)\s*lint:/){s/^\s*(#|\/\/)\s*lint:\s*//; print $_; exit}' "$@"
