#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-01-23 20:15:52 +0000 (Tue, 23 Jan 2024)
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
For each Wordpress post (article), checks its Categories and if a corresponding Tag of the same slug exists but isn't assigned to the post, prints it

Useful check if you want to have matching tags for a tag cloud that are aligned with your categories

Uses wordpress_api.sh - see its --help for details on what environment variables need to be set:

        $srcdir/wordpress_api.sh --help

Limitation: doesn't iterate more than 100 categories or tags, extend code if you really have that many to process

Requires curl to be installed
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

#min_args 1 "$@"
no_more_args "$@"

api="$srcdir/wordpress_api.sh"

# XXX: not bothered iterating categories or tags - expand this if you have more than 100 categories or tags
timestamp "getting list of available categories"
category_map="$("$api" /categories?per_page=100 | jq -r '.[] | [.id, .slug] | @tsv')"
timestamp "getting list of available tags"
tag_map="$("$api" /tags?per_page=100 | jq -r '.[] | [.id, .slug] | @tsv')"

for((page=1;; page++)); do
    if [ "$page" -gt 100 ]; then
        die "Hit over 100 pages of teams, possible infinite loop, exiting..."
    fi
    if [ -z "${QUIET:-}" ]; then
        timestamp "getting list of posts: page $page"
    fi
    data="$("$api" "/posts?per_page=100&page=$page" | jq_debug_pipe_dump)"
    if jq_is_empty_list <<< "$data"; then
        break
    fi
    jq -r '.[] | [.id, .slug] | @tsv' <<< "$data" |
    while read -r post_id post_slug; do
        #if [ -z "${QUIET:-}" ]; then
        #    timestamp "checking post '$post_slug'"
        #fi
        category_ids="$(jq -r ".[] | select(.id == $post_id) | .categories[]" <<< "$data")"
        tag_ids="$(jq -r ".[] | select(.id == $post_id) | .tags[]" <<< "$data")"
        #new_tags="$tag_ids"
        for category_id in $category_ids; do
            category_slug="$(awk "/^${category_id}[[:space:]]/{print \$2}" <<< "$category_map")"
            tag_slug="$category_slug"
            tag_id="$(awk "/[[:space:]]$tag_slug$/{print \$1}" <<< "$tag_map" || :)"
            [ -z "$tag_id" ] && continue
            if ! grep -Fxq "$tag_id" <<< "$tag_ids"; then
                timestamp "post '$post_slug' is missing tag '$tag_slug'"
                #new_tags+=$'\n'"$tag_id"
                #new_tags_array="[ $(tr '\n' ',' <<< "$new_tags" | sed 's/,$//') ]"
                #timestamp "adding post '$post_slug' tag '$tag_slug': $new_tags_array"
                #data="$("$api" "/posts/$post_id" -X POST -d "{ \"tags\": $new_tags_array }" | jq_debug_pipe_dump)"
            fi
        done
        #post_data="$("$api" / | jq_debug_pipe_dump)"
    done
    if jq -e 'length < 100' <<< "$data" >/dev/null; then
        break
    fi
done
