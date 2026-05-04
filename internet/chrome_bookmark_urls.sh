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

Useful to combine with another tool like chrome.sh to open all those tabs in a staggered way to not overload a website
and result in HTTP 429 Too Many Requests errors and time banning

You can specify the Google Chrome profile other than the Default profile - these may be called 'Profile N'
instead of the name you see in your browser. You will need to investigate your directory structure to find this under:

    \$HOME/.config/google-chrome/\$profile

        or on Mac:

    \$HOME/Library/Application Support/Google/Chrome/\$profile

You can also specify a subdirectory structure to return URLs from, for example if you have a

    Cities -> Czech Republic -> Prague

folder structure that you want to extract only from under there:

    ${0##*/} 'Profile 5' 'Cities.Czechia.Prague'
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<profile> <folder.folder2.folder3>]"

help_usage "$@"

#min_args 1 "$@"

profile="${1:-Default}"

folder_path="${2:-.}"

bookmarks_path="$HOME/.config/google-chrome/$profile/Bookmarks"

if is_mac; then
    bookmarks_path="$HOME/Library/Application Support/Google/Chrome/$profile/Bookmarks"
fi

jq -r --arg path "$folder_path" '
    ($path | select(. != "" and . != ".") | split(".")) as $parts

    | def descend($node; $names):
        if ($names | length) == 0 then
            $node
        else
            (
                $node.children
                | map(select(.type == "folder" and .name == $names[0]))[0]
            ) as $next
            | if $next == null then empty
                else descend($next; $names[1:])
            end
        end;

  descend(.roots.bookmark_bar; $parts)
  | .children[]
  | select(.type == "url")
  | .url
' "$bookmarks_path"
