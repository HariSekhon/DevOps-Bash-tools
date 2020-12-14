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
gcp_lib_srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$gcp_lib_srcdir/utils.sh"

gcp_info_noninteractive_help="You should only this script non-interactively / in pipes once you have tested it locally on the command line because some services may prompt you for choices, eg. Cloud Run, which you should save to your GCloud SDK config settings first"

gcp_info_formatting_help="In interactive mode, prints fancy boxes around GCP info to be easier on the eye. In non-interactive mode it skips formatting so it's easier to parse or process with other commands like grep / awk etc. Non-interactive mode happens automatically when the output is piped or redirected to a file or another command, or when \$NO_FORMATTING=1 is set in environment"

if is_piped || [ -n "${NO_FORMATTING:-}" ]; then
    gcloud_formatting=''
else
    # want deferred expansion
    # shellcheck disable=SC2016
    gcloud_formatting='"[box,title=\"$title\"]"'
fi

# not anchoring here any more so that we can use these to compose more complex regex - client should anchor regex in matches
gcr_image_regex='([^\.]+\.)?gcr\.io/[^/]+/[^:]+'
gcr_image_tag_regex="$gcr_image_regex:.+"
gcr_image_optional_tag_regex="$gcr_image_regex(:.+)?"

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
