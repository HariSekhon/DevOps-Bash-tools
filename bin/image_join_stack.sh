#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-08-28 14:37:45 +0200 (Wed, 28 Aug 2024)
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
Stack joins two images after matching their widths so they align correctly

If the third arg is not given then outputs to joined_image.png

Requires ImageMagick to be installed and configured
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<top_image> <bottom_image> [<output_image>]"

help_usage "$@"

min_args 2 "$@"
max_args 3 "$@"

check_bin magick

top_image="$1"
bottom_image="$2"
output_image="${3:-joined_image.png}"

top_image_width="$(magick identify -format "%w" "$top_image")"
bottom_image_width="$(magick identify -format "%w" "$bottom_image")"

if [ "$top_image_width" -lt "$bottom_image_width" ]; then
    resized_image="${bottom_image%.*}.resized.${bottom_image##*.}"
    timestamp "Resizing bottom image '$bottom_image' which has width '$bottom_image_width' to match '$top_image' width of '$top_image_width' => $resized_image"
    # convert or magick convert is deprecated in ImageMagick version 7 (IMv7) - use just 'magick' instead now
    #magick convert "$bottom_image" -resize "x$top_image_width!" "$resized_image"
    magick "$bottom_image" -resize "$top_image_width" "$resized_image"
    bottom_image="$resized_image"
    echo >&2
elif [ "$top_image_width" -gt "$bottom_image_width" ]; then
    resized_image="${top_image%.*}.resized.${top_image##*.}"
    timestamp "Resizing top image '$top_image' which has width '$top_image_width' to match '$bottom_image' width of '$bottom_image_width' => $resized_image"
    # deprecated, see comment above
    #magick convert "$top_image" -resize "x$bottom_image_width!" "$resized_image"
    magick "$top_image" -resize "$bottom_image_width" "$resized_image"
    top_image="$resized_image"
    echo >&2
elif [ "$top_image_width" -eq "$bottom_image_width" ]; then
    timestamp "Image widths already match, joining as is"
    echo >&2
else
    die "ERROR: logic error, please check code"
fi

timestamp "Joining top image '$top_image' and bottom image '$bottom_image' into output image '$output_image'"
# deprecated, see comment above
#magick convert "$top_image" "$bottom_image" -append "$output_image"
magick "$top_image" "$bottom_image" -append "$output_image"
echo >&2
timestamp "Stacked image created: $output_image"
if is_mac; then
    echo >&2
    timestamp "Opening image: $output_image"
    open "$output_image"
fi
