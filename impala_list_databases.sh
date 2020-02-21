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

# Lists all Impala databases using adjacent impala_shell.sh script
#
# FILTER environment variable will restrict to matching databases (if giving <db>.<table>, matches up to the first dot)
#
# Tested on Impala 2.7.0, 2.12.0 on CDH 5.10, 5.16 with Kerberos and SSL
#
# For more documentation see the comments at the top of impala_shell.sh

# For a better version written in Python see DevOps Python tools repo:
#
# https://github.com/harisekhon/devops-python-tools

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

# strip comments after database name, eg.
# default Default Hive database
"$srcdir/impala_shell.sh" --quiet -Bq 'SHOW DATABASES' "$@" |
awk '{print $1}' |
while read -r db; do
    if [ -n "${FILTER:-}" ] &&
       ! [[ "$db" =~ ${FILTER%%.*} ]]; then
        continue
    fi
    printf "%s\n" "$db"
done
