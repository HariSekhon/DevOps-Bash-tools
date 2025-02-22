#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: Thu Dec 5 00:39:05 2024 +0700
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
Converts one or more Terraform Registry URLs from tfr:// to https://registry.terraform.io/ format

URLs can be given as a string argument, file or standard input containing URLs

Used by .vimrc to convert tfr:// URLs found in a file to HTTPS format to present in a menu

Very useful for quickly referencing Terraform documentation for modules defined in Terraform code
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<tfr_url_or_file_with_tfr_urls>]"

help_usage "$@"

max_args 1 "$@"

arg="${1:-}"

if [ $# -eq 0 ]; then
    cat
elif [ -f "$arg" ]; then
    cat "$arg"
else
    echo "$arg"
fi |
sed '
    /tfr/{
        s|tfr://registry.terraform.io/|https://registry.terraform.io/modules/|;
        s|$|/latest|g;
    }
'
