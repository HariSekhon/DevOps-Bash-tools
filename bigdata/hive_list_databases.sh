#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-12-06 11:10:26 +0000 (Fri, 06 Dec 2019)
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
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
List all Hive databases via beeline

Output Format:

<database_name>


FILTER environment variable will restrict to matching databases (if giving <db>.<table>, matches up to the first dot)


Tested on Hive 1.1.0 on CDH 5.10, 5.16


For a better version written in Python see DevOps Python tools repo:

    https://github.com/HariSekhon/DevOps-Python-tools

you will need to comment out / remove '-o pipefail' below to skip errors if you aren't authorized to use
any of the databases to avoid the script exiting early upon encountering any authorization error such:

ERROR: AuthorizationException: User '<user>@<domain>' does not have privileges to access: default   Default Hive database.*.*
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<beeline_options>]"

help_usage "$@"


"$srcdir/beeline.sh" --silent=true --outputformat=tsv2 -e 'SHOW DATABASES' "$@" |
tail -n +2 |
# awk '{print $1}' |
while read -r db; do
    if [ -n "${FILTER:-}" ] &&
       ! [[ "$db" =~ ${FILTER%%.*} ]]; then
        continue
    fi
    printf '%s\n' "$db"
done
