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
Opens the Terraform Registry URL in either tfr:// or https://registry.terraform.io/ format

URL can be given as a string arg, file or standard input

If the given arg is a file, then opens the first Terraform URL found in the file

Used by .vimrc to instantly open a URL on the given line in the editor

Very useful for quickly referencing Terraform documentation for modules defined in Terraform code
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<url_or_file_with_url>]"

help_usage "$@"

max_args 1 "$@"

#if "$srcdir/terraform_registry_url_extract.sh" "$@" |
#    sed 's|tfr://registry.terraform.io/|https://registry.terraform.io/modules/|; s|$|/latest|g'
#    then
#    timestamp "Found Terraform Registry URL(s)"
#elif "$srcdir/../bin/urlextract.sh" "$@"; then
#    timestamp "Found URL(s)"
#fi |

"$srcdir/terraform_registry_url_extract.sh" "$@" |
"$srcdir/terraform_registry_url_to_https.sh" |
# head -n1 because grep -m 1 can't be trusted and sometimes outputs more matches on subsequent lines
head -n1 |
"$srcdir/../bin/urlopen.sh"
