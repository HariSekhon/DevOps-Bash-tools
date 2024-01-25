#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-12-10 11:33:52 +0000 (Tue, 10 Dec 2019)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# you will almost certainly have to comment out / remove '-o pipefail' to skip authorization errors such as that documented in impala_list_tables.sh
set -eu  # -o pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Show table location for all tables via beeline

Output Format:

<db>.<table>    <location>


FILTER environment variable will restrict to matching fully qualified tables (<db>.<table>)


Tested on Hive 1.1.0 on CDH 5.10, 5.16


For more documentation see the comments at the top of beeline.sh

For a better version written in Python see DevOps Python tools repo:

    https://github.com/HariSekhon/DevOps-Python-tools
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<beeline_options>]"

help_usage "$@"


exec "$srcdir/hive_tables_metadata.sh" Location "$@"
