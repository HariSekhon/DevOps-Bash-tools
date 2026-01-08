#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  stdin: Driving &amp; road trips
#
#  Author: Hari Sekhon
#  Date: 2025-12-23 22:01:42 -0600 (Tue, 23 Dec 2025)
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
Decodes HTML encoding

Detects available tools such as Perl, Python or xmlstarlet and uses whatever is available

Works like a standard filter program, takes file arguments for contents or reads from standard input

Writen to clean up Spotify playlist descriptions such as:

    Driving &amp; road trips ...

to

    Driving & road trips...

Used by spotify_playlist_description.sh
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<files>]"

help_usage "$@"

#min_args 1 "$@"

cat "$@" |
if type -P perl &>/dev/null &&
   perl -MHTML::Entities -e '' &>/dev/null; then
    log "Decoding HTML using Perl"
    perl -MHTML::Entities -pe 'decode_entities($_)'
elif type -p python3 &>/dev/null &&
    log "Decoding HTML using Python"
    python3 -c 'import html' &>/dev/null; then
    python3 -c 'import sys, html; sys.stdout.write(html.unescape(sys.stdin.read()))'
elif type -p xmlstarlet; then
    log "Decoding HTML using xmlstarlet"
    xmlstarlet unesc
else
    echo "ERROR: neither Perl HTML::Entities nor xmlstarlet are available" >&2
    exit 1
fi
