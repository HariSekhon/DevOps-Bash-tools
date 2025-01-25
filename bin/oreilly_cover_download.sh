#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-01-25 19:57:12 +0700 (Sat, 25 Jan 2025)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
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
Downloads an O'Reilly book cover

Gives a nice interactive menu or Book Titles and Animal names to scroll through

Use an ERE regex argument to filter this list to be shorter

If the regex only matches a single item then skips the interactive menu and downloads it directly


Requires dialogue menu CLI tool to be installed - attempts to install it via OS package manager if not already found
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<regex_filter>]"

help_usage "$@"

#max_args 1 "$@"

regex="${*:-.}"

# https://gist.github.com/briandfoy/d68915eb425e1fc4932ceac5cdf2d60d
#
# forked to
#
# https://gist.github.com/HariSekhon/4374b779ef3f79e5f28cbb8ca0d3b31b

# gh gist view --raw d68915eb425e1fc4932ceac5cdf2d60d --filename oreilly-animals.json > ../resources/oreilly-animals.json

json="$srcdir/../resources/oreilly-animals.json"

if ! type -P dialog &>/dev/null; then
    timestamp "Dialog not found in \$PATH, attempting to install via OS package manager"
    echo
    "$srcdir/../packages/install_packages.sh" dialog
    echo
fi

timestamp "Parsing Titles"
titles="$(jq -Mr '.[].title' < "$json" | grep -Ei "$regex" || :)"

timestamp "Parsing Animals"
animals="$(jq -Mr '.[].animal' < "$json" | grep -Ei "$regex" || :)"

menu_items=()
menu_tag_items=()

while read -r line; do
    # used for counting and string conversion if only a single item matches regex
    menu_items+=("$line")

    # passed to dialog because it requires args: tag1 visibletext tag2 visibletext
    # - by making the second one blank it uses the item as both the tag to be returned
    # to script as well as the visible text
    menu_tag_items+=("$line" " ")

done < <( { echo "$titles"; echo "$animals"; } | sed '/^[[:space:]]*$/d' | sort -fu )

if [ "${#menu_items[@]}" -eq 0 ];then
    die "Error: No Book Titles or Animals found matching regex: $regex"
elif [ "${#menu_items[@]}" -eq 1 ];then
    selected="${menu_items[*]}"
else
    selected="$(dialog --menu "Choose Book Title or Animal:" "$LINES" "$COLUMNS" "$LINES" "${menu_tag_items[@]}" 3>&1 1>&2 2>&3)"
fi

timestamp "Selected: $selected"

timestamp "Getting corresponding URL"
url="$(jq -r "limit(1; .[] | select(.title == \"$selected\" or .animal == \"$selected\") ) | .cover_src" < "$json")"

timestamp "Downloading: $url"

download_file="$selected.${url##*.}"

timestamp "Downloading to file: $download_file"

wget -nc -O "$selected.${url##*.}" "$url"

timestamp "Download complete"

echo >&2

"$srcdir/../media/imageopen.sh" "$download_file"
