#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-12-10 11:33:52 +0000 (Tue, 10 Dec 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Show table location for all tables via Impala shell
#
# Tested on Hive 1.1.0 on CDH 5.10, 5.16
#
# For more documentation see the comments at the top of beeline.sh

# For a better version written in Python see DevOps Python tools repo:
#
# https://github.com/harisekhon/devops-python-tools

# you will almost certainly have to comment out / remove '-o pipefail' to skip authorization errors such as that documented in impala_list_tables.sh
set -eu  # -o pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

"$srcdir/hive_tables_metadata.sh" Location "$@"
