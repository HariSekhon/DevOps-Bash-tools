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
Shrinks an image by resizing it (default 50%) to be able to upload it against limits on some websites

Quickly written to be able to upload a 4.2MB passport pic to the Copa airline flight to Panama as its limit was 4MB
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<iamge_file> [<percentage_to_shrink_to>]"

help_usage "$@"

min_args 1 "$@"
max_args 2 "$@"

input_image="$1"
percentage="${2:-50%}"
percentage="${percentage%%%}"

if ! is_int "$percentage"; then
    die "Second arg for percentage must be an integer"
fi

if [ "$percentage" -lt 2 ] || [ "$percentage" -gt 98 ]; then
    die "Percentage must be between 2 and 98 %"
fi

output_image="${input_image%.*}.size.$percentage%.${input_image##*.}"

timestamp "Shrinking image '$input_image' to $percentage% => '$output_image'"
echo >&2

magick "$input_image" -resize "$percentage"% "$output_image"

timestamp "Before vs After:"
echo >&2

{
magick identify "$input_image"
magick identify "$output_image"
} | column -t

"$srcdir/imageopen.sh" "$output_image"
