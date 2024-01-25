#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-09-27 17:12:39 +0100 (Fri, 27 Sep 2019)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Prints the Perl @INC paths, one per line

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

# copied from old bashrc function which is now ported under .bash.d/ too, but given here for convenience in case you are not running the full bash profile
perl -e 'print join("\n", @INC);'
