#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-09-04 14:42:02 +0200 (Wed, 04 Sep 2024)
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

default_url="https://raw.githubusercontent.com/HariSekhon/HariSekhon/main/README.md"

# shellcheck disable=SC2034,SC2154
usage_description="
Replaces the repos block of a given markdown file

Pulls from here by default if no url is specified:

    $default_url

Requires the markdown file to have lines with

<!-- OTHER_REPOS_START -->

    and

<!-- OTHER_REPOS_END -->

lines to demark the repos block


If no file is given but README.md is found in the \$PWD, then uses that
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<README.md> <url>]"

help_usage "$@"

max_args 2 "$@"

markdown_file="${1:-README.md}"
url="${2:-$default_url}"

other_repos_tmp="$(mktemp)"
other_repos_tmp2="$(mktemp)"

markdown_tmp="$(mktemp)"

if ! [ -f "$markdown_file" ]; then
    die "File not found: $markdown_file"
fi

# check the tags existing in the markdown file otherwise we can't do anything
for x in OTHER_REPOS_START OTHER_REPOS_END; do
    if ! grep -q "<!--.*$x.*-->" "$markdown_file"; then
        die "Markdown file '$markdown_file' is missing the other repos section boundary comment <!--.*$x.*-->"
    fi
done

timestamp "Fetching other repos section for file '$markdown_file' from $url"

curl -sS "$url" > "$other_repos_tmp"

if [ -z "$other_repos_tmp" ]; then
    die "URL returned empty content: $url"
fi

for x in REPOS_START REPOS_END; do
    if ! grep -q "<!--.*$x.*-->" "$other_repos_tmp"; then
        die "URL content is missing the other repos section boundary comment <!--.*$x.*-->"
    fi
done

# copy out content between REPOS_START and REPOS_END lines
sed -n '/REPOS_START/,/REPOS_END/{
    /REPOS_START/,/REPOS_END/{
        /REPOS_START/b;
        /REPOS_END/b;
        p;
    }
}' "$other_repos_tmp" |
# strip leading and trailing whitespace lines
sed '/./,$!d' |
tac |
sed '/./,$!d' |
tac > "$other_repos_tmp2"

#unalias mv &>/dev/null || :
mv -f "$other_repos_tmp2" "$other_repos_tmp"

timestamp "Replacing other other repos section in file: $markdown_file"

sed -n "
    1,/OTHER_REPOS_START/p

    /OTHER_REPOS_START/ a

    /OTHER_REPOS_START/,/OTHER_REPOS_END/ {
        /OTHER_REPOS_START/ {
            r $other_repos_tmp
        }
    }

    /OTHER_REPOS_END/ i

    /OTHER_REPOS_END/,$ p
" "$markdown_file" > "$markdown_tmp"

mv -f "$markdown_tmp" "$markdown_file"

#unalias rm &>/dev/null || :
rm -f "$other_repos_tmp"

timestamp "Replaced other repos section in file: $markdown_file"
