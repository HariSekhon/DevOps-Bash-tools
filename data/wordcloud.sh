#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-11-23 02:12:38 +0400 (Sat, 23 Nov 2024)
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
Creates a wordcloud from file(s) or stdin using ImageMagick
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<wordcloud.png>]"

help_usage "$@"

max_args 1 "$@"

png="${1:-wordcloud.png}"

#wordcounts="$(mktemp)"

#timestamp "Running wordcount.sh"
#"$srcdir/wordcount.sh" "$@" |
#awk '$2 !~ /^[^[:alnum:]]+$/' |
#awk '$2 !~ /^[[:digit:]]+$/' \
#> "$wordcounts"

timestamp "Running wordcloud_cli"
#wordcloud_cli --text "$wordcounts" --imagefile "$png"
wordcloud_cli --imagefile "$png"

#expanded_words="$(mktemp)"
#
#timestamp "Generating word expansion"
#awk '{for (i=1; i<=$1; i++) printf $2 " ";}' < "$wordcounts" > "$expanded_words"
#
#timestamp "Generating PNG '$png' using ImageMagick"
#magick \
#    -size 800x600 \
#    xc:white \
#    -font Arial \
#    -pointsize 20 \
#    -gravity center \
#    -annotate 0 \
#    @"$expanded_words" \
#    "$png"

timestamp "Opening '$png'"
"$srcdir/../media/imageopen.sh" "$png"
