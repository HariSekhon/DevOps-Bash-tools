#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-12-24 01:31:35 -0600 (Wed, 24 Dec 2025)
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
Shrinks an image by 50% to be able to upload it against limits on some websites

Quickly written to be able to upload a 4.2MB passport pic to the Copa airline flight to Panama as its limit was 4MB
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<iamge_file>"

help_usage "$@"

num_args 1 "$@"

input_image="$1"

output_image="${input_image%.*}.50%.${input_image##*.}"

timestamp "Shrinking image '$input_image' by 50% to '$output_image'"

magick "$input_image" -quality 80 "$output_image"
