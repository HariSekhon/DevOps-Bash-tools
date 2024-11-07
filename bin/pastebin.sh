#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2010-05-18 10:40:36 +0100 (Tue, 18 May 2010)
#  (just discovered in private repo and ported here)
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
Uploads a file to https://pastebin.com

Make sure to carefully review what you're about to upload publicly!!

Required: an API key in environment variable PASTEBIN_API_KEY

Recommended: use anonymize.py or anonymize.pl from the adjacent DevOps-Python-tools or DevOps-Perl-tools repos

Optional: decomment.sh

TODO: Auto-infers the format to tell the API based on the file extension

Expiry defaults to 1 day

See values for parameters here:

    https://pastebin.com/doc_api#4

Knowledge Base page: https://github.com/HariSekhon/Knowledge-Base/blob/main/upload-sites.md
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<filename> [<expiry> <private> <format>]"

help_usage "$@"

min_args 1 "$@"

check_env_defined PASTEBIN_API_KEY

file="$1"
expiry="${2:-${PASTEBIN_EXPIRY:-1D}}"
private="${3:-1}"  # 1=unlisted (default), 0=public, 2=private
format="${4:-text}"  # syntax highlighting

if ! [[ "$private" =~ ^(0|1|2)$ ]]; then
    usage "Invalid value for private arg, must be one of: 0, 1 or 2 for public, unlisted or private respectively"
fi

if ! [[ "$expiry" =~ ^[[:digit:]][[:alpha:]]$ ]]; then
    usage "Invalid value for expiry arg, must be in format: <num><unit>"
fi

# Do not allow reading from stdin because it does not allow the prompt safety
#if [ "$file" = '-' ]; then
#    timestamp "reading from stdin"
    #file="/dev/stdin"
#else
    timestamp "reading from file: $file"
#fi

content="$(cat "$file")"
echo

cat <<EOF
Here is what will be pastebin-ed:

$content

EOF

read -r -p "Continue? [y/N] " answer
echo

check_yes "$answer"
echo

filename_encoded="$("$srcdir/urlencode.sh" <<< "$file")"

curl -X POST -sSLf https://pastebin.com/api/api_post.php \
     -d "api_option=paste" \
     -d "api_dev_key=$PASTEBIN_API_KEY" \
     -d "api_paste_name=$filename_encoded" \
     -d "api_paste_code=$content" \
     -d "api_paste_format=$format" \
     -d "api_paste_expire_date=$expiry" \
     -d "api_paste_private=$private" \
     | tee /dev/stderr |
     "$srcdir/copy_to_clipboard.sh"
echo
