#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2023-04-24 22:04:05 +0100 (Mon, 24 Apr 2023)
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
Creates a word count list ranked by most used words at the top

Works like a standard unix filter program - pass in stdin or give it a filename, and outputs to stdout, so you can continue to pipe or redirect to a file as usual

If the filename arg is a .pdf file then uses pdftotext to dump out the words
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<filename>]"

help_usage "$@"

#min_args 1 "$@"

#filename="$1"

if [ $# -eq 0 ]; then
    echo "Reading from stdin" >&2
fi

#output_file="$filename.word_frequency.txt"

shopt -s nocasematch
if [[ "${1:-}" =~ \.pdf ]]; then
    pdftotext "$1" -
else
    # one of the few legit uses of cat - tr can't process a filename arg or stdin
    cat "$@"
fi |
#tr '[:punct:]' ' ' |
tr '[:space:]' '\n' |
tr '[:upper:]' '[:lower:]' |
sed "
    /^[[:space:]]*$/d;
    #/^$USER$/d;
    # because sometimes you want to see the occurence of emojis in WhatsApp chats
    #/^[^[:alnum:]]*$/d;
" |
sort |
uniq -c |
sort -k1nr  # > "$output_file"

#head -n "$LINES" "$output_file"
