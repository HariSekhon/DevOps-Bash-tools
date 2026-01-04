#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2026-01-04 15:55:47 -0500 (Sun, 04 Jan 2026)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn
#  and optionally send me feedback to help steer this or other code I publish
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
Prints your 100 most used Bash commands, taking in to account whether your shell history is in basic or extended format

Eg. Handles both

    <num> <command>

and

    <num> <date> <time> <command>

Because shell scripts do not have access to the interactive history, this uses ~/.bash_history file
and parses out timestamps

Caveat: this will not include current shell's commands which are usually only written upon shell exit

To include the current shell, do a one liner like this:

    history | awk '{ a[\$2]++ } END { for(i in a) { print a[i] \" \" i } }' | sort -rn | head -n 100

Or if you're using timestamped shell history:

    history | awk '{ a[\$4]++ } END { for(i in a) { print a[i] \" \" i } }' | sort -rn | head -n 100
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

no_more_args "$@"

#timestamped_history=0

#if history | grep -P '^\d+\s+\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}\s'; then
#    timestamped_history=1
#fi

# doesn't work
#"$SHELL" -c history |
# if you were piping live history only, but format of ~/.bash_history is different
#if [ "$timestamped_history" = 1 ]; then
#    awk '{ a[$4]++ } END { for(i in a) { print a[i] " " i } }'
#else
#    awk '{ a[$2]++ } END { for(i in a) { print a[i] " " i } }'
#fi |
#
# filter out timestamp epoch lines prefixed with a hash
sed '/^#/d' ~/.bash_history |
awk '{ a[$1]++ } END { for(i in a) { print a[i] " " i } }' |
sort -rn |
head -n 100
