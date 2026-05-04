#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2026-05-04 15:49:24 +0200 (Mon, 04 May 2026)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn
#  and optionally send me feedback
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
Parses the Google Chrome bookmark URLs and prints them one per line

Supports different profiles and querying specific Bookmarks subfolders

Useful to combine with another tool like chrome.sh to open all those tabs in a staggered throttled way
in order to avoid overloading a website, which often results in HTTP 429 Too Many Requests errors and time banning

You can specify the Google Chrome profile other than the Default profile - these may be called 'Profile N'
instead of the name you see in your browser and they aren't necessary continugous numbers either
(perhaps you created and deleted profiles).

You will need to investigate your directory structure to find these profile names under here on Linux:

    \$HOME/.config/google-chrome/\$profile

Or under here on Mac:

    \$HOME/Library/Application Support/Google/Chrome/\$profile


You can also specify the Bookmarks folder structure to return URLs for bookmarks only within that folder and its subfolders.

For example if you have a Bookmarks folder structure like this:

    Cities -> Czech Republic -> Prague

You can call this script like this to give only the URLs under there:

    ${0##*/} 'Profile 5' 'Cities.Czechia.Prague'
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<profile> <folder.subfolder2.subfolder3>]"

help_usage "$@"

#min_args 1 "$@"

profile="${1:-Default}"

folder_path="${2:-.}"

bookmarks_path="$HOME/.config/google-chrome/$profile/Bookmarks"

if is_mac; then
    bookmarks_path="$HOME/Library/Application Support/Google/Chrome/$profile/Bookmarks"
fi

jq -r --arg path "$folder_path" '
    def urls_recursive:
        if .type == "url" then
            .url
        elif .type == "folder" then
            (.children // [])[] | urls_recursive
        else
            empty
        end;

    def descend($node; $names):
        if ($names | length) == 0 then
            $node
        else
            ($node.children // [])
            | map(
                    select(
                        .type == "folder"
                            and
                        (.name | ascii_downcase) == ($names[0] | ascii_downcase)
                    )
                )[0] as $next
            | if $next == null then empty
                else descend($next; $names[1:])
                end
        end;

    # parse path
    ($path | if . == "" or . == "." then [] else split(".") end) as $parts

    # choose starting point, then recurse
    | .roots
    | to_entries[]
    | .value
    | descend(.; $parts)
    | urls_recursive
' "$bookmarks_path"
