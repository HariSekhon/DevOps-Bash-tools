#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  shellcheck disable=SC1090,SC2034
#
#  Author: Hari Sekhon
#  Date: 2020-08-13 19:38:39 +0100 (Thu, 13 Aug 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

gcp_info_formatting_help="Prints fancy boxes around GCP info in interactive mode. Skips formatting if the output is sent through a pipe to other commands, redirected to file, or \$NO_FORMATTING=1 is set in environment, to allow for easier parsing / grepping"

if is_piped || [ -n "${NO_FORMATTING:-}" ]; then
    gcloud_formatting=''
else
    # want deferred expansion
    # shellcheck disable=SC2016
    gcloud_formatting='"[box,title=\"$title\"]"'
fi

gcr_image_regex='^([^\.]+\.)?gcr\.io/[^/]+/[^:]+$'
gcr_image_tag_regex='^([^\.]+\.)?gcr\.io/[^/]+/[^:]+:.+$'
gcr_image_optional_tag_regex='^([^\.]+\.)?gcr\.io/[^/]+/[^:]+(:.+)?$'

gcp_info(){
    local title="$1"
    shift || :
    if [ -z "$gcloud_formatting" ]; then
        #perl -e "print '=' x (${#title} + 1);"
        for ((i=0; i <= ${#title}; i++)); do
            #printf '='
            # built-in - not as portable eg. sh, but given we explicitly execute in bash should be ok
            echo -n '='
        done
        echo
        echo "$title:"
    fi
    if [[ "$*" =~ --format ]]; then
        # eval formatting for table only to get late evaluated $title
        "${@//--format=table(/--format=table$(eval echo "$gcloud_formatting")(}"
    else
        # formatting has to be eval'd in order to pick up latest $title as a late binding
        # better than eval'ing the entire command line to evaluate $title in the formatting string interpolation
        "$@" --format="$(eval echo "$gcloud_formatting")" || return
        if [ -z "$gcloud_formatting" ]; then
            echo
        fi
    fi
}
